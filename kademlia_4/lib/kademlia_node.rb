#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

require 'rest_client'

class KademliaNode
	@@alpha = 3		# degree of paralellism in network calls
	@@B = 256 		# number of bits in a SHA256 digest, e.g. 256.
	@@k = 8 		# maximum number of stored contacts per bucket.

	@@tExpire = 86500 		#time after which a key/value pair expires. Time To Live from *original* publication date. Note that this is significantly longer than tRepublish to prevent a race condition.
	@@tRefresh = 3600 		#time after which an otherwise unaccessed bucket must be refreshed.
	@@tReplicate = 3600 	#Interval between republication events, when a node is required to publish its entire database.
	@@tRepublish = 86400 	#time after which the original publisher must republish a key/value pair for it not to disappear.



	attr_accessor :node_id, :identifier, :data_store, :bucket_list, :server

	#identifier is used to determine the node ID. Should be a quasi-random number.
	def initialize(identifier, host, port, path="/", known_nodes=[])

		@logger = Logger.new(STDOUT)
		@logger.level = Logger::DEBUG
		@logger.progname = "`#{identifier}`"



		@identifier = identifier.to_s
		@node_id = $digest_class.digest @identifier
		@data_store = HashTable.new("data_store/#{identifier}") #Value Store, keys are hash digests of the values.

		 # Buckets of contacts. 
		 # for bucket j, where 0 <= j <= k, 2^j <= calc_distance(node.node_id, contact.node_id) < 2^(j+1) 
		@bucket_list = KademliaBucketList.new(self.node_id, {max_bucket_size:@@k})

		known_nodes.each do |contact|
			@bucket_list << contact
		
		end

		@host = host
		@port = port
		@path = path
		@server = KademliaServer.new(self, @port)

	end

	def to_contact
		#TODO: Init server with custom location.
		KademliaContact.new(@node_id, "127.0.0.1", self.server.port)
	end

	def ping(contact)
		contact.client do |c|
			c.ping(self.to_contact)
		end

	end

	def handle_ping(contact_info)
		@logger.info "returning pong to ping"
		@logger.info "adding node #{contact_info}"
		@bucket_list << KademliaContact.from_hash(contact_info)
		#self.add_contact_to_buckets(KademliaContact.from_hash(contact_info))
		return self.to_contact
	end

	#Primitive operation to require contact to store data.
	def store(contact, key, value)
		contact.client do |c|
			c.store(key, value)
		end
		@logger.info "Value stored. Reference key: `#{key}`"
	end

	def handle_store(key, value)
		#key = $digest_class.digest value
		actual_key = @data_store.store(key, value)
		@logger.info "Storing `#{key}` => `#{value}`) on server #{@identifier}"
		@logger.info "Stored under key `#{actual_key}"
		return actual_key
	end

	#Primitive operation to require contact to return up to @@k KademliaContacts closest to given key
	def find_node(contact, key_hash)
		@logger.info "searching for closest node."
		contact.client do |c| 
			@logger.info "Searching on #{contact.inspect}"
			hashed_contacts = c.find_node(key_hash)
			@logger.info "hashed contacts: #{hashed_contacts}"
			result = hashed_contacts.map{|hashed_contact| KademliaContact.from_hash(hashed_contact)}
			@logger.info "result of find_node: `#{result}`"
			return result
		end
		return []
	end

	def handle_find_node(key_hash)
		sorted_contacts = @bucket_list.closest_contacts(key_hash) #(@bucket_list.flatten).sort {|a,b| self.calc_distance(key_hash,a.node_id) <=> self.calc_distance(key_hash,b.node_id)}
		result = sorted_contacts.take(@@k).map {|contact| contact.to_hash}
		@logger.info "Returning closest nodes: `#{result}`"
		return result
	end

	#Primitive operation to ask contact to return either:
	# => the value for the specific key_hash, if he has it.
	# => if not, return the result of `#find_node` (closest contacts that might know it)
	def find_value(contact, key_hash)
		result = nil
		contact.client do |c|
			@logger.info "Calling RPC `find_value` on #{contact.inspect}"
			result = c.find_value(key_hash)
		end
		return result
	end

	def handle_find_value(key_hash)
		@logger.info "`handle_find_value` called with key_hash=`#{key_hash}`"


		if @data_store.include?(key_hash)
			kvalue = @data_store[key_hash] #TODO: Timeouts
			@logger.info "found value on this node. Returning `#{key_hash}` => `#{kvalue.inspect}`"
			return {found: true, key: key_hash, value: kvalue.value} 
		else
			@logger.info "value for `#{key_hash}` not found. Returning closest nodes."
			return {found: false, closest_nodes: handle_find_node(key_hash)}
		end
	end

	#Iterative node lookup.
	def iterative_find_node(key_hash, use_find_value=false)

		shortlist = @bucket_list.find_bucket_for(key_hash).contacts.clone
		closest_node, closest_distance = save_closest_contact(shortlist, key_hash)
		already_contacted_contacts = [self.to_contact] #Never add yourself to the shortlist.
		probed_contact_amount = 0

		#TODO: Paralellism using @@alpha

		while shortlist.any?
			contact = shortlist.shift

			begin
				if use_find_value then
					result = find_value(contact, key_hash)
					@logger.info result
					if result["found"] then
						#Save result in closest node that did *not* return the value
						store(closest_node, result["key"], result["value"])

						return result
					else
						new_shortlist = result["closest_nodes"].map{|hashed_contact| KademliaContact.from_hash(hashed_contact)}
						@logger.info new_shortlist
					end
				else
					new_shortlist = find_node(contact, key_hash)
				end
			rescue Exceptions::KademliaClientConnectionError => e
				@logger.info "Contact #{contact.identifier} did not respond to `find_*` RPC. Skip to next."
				next #In the case of an error connecting to a contact, skip to the next one in the shortlist.
			end
			already_contacted_contacts << contact
			
			shortlist += new_shortlist #add all new contacts

			shortlist -= already_contacted_contacts #remove all contacts that have been contacted before.

			new_closest_node, new_closest_distance = save_closest_contact(new_shortlist, key_hash)
			if new_closest_distance < closest_distance then
				closest_distance = new_closest_distance
				closest_node = new_closest_node
			end


			probed_contact_amount += 1
			break if probed_contact_amount >= @@k

			#TODO: wait until calls return
		end


		#If no value, return a list of max @@k nodes that are closest to it.
		return bucket_list.closest_contacts(key_hash) #@bucket_list.flatten.sort {|a,b| calc_distance(a.node_id, key_hash) <=> calc_distance(b.node_id, key_hash)}.take(@@k)
	end

	def iterative_store(key, value)
		#key = $digest_class.digest value
		self.handle_store(key, value) #Also store locally, as there is a high possibility that it will be re-requested by uploader.
		
		closest_contacts = iterative_find_node(key)
		closest_contacts.each do |contact|
			Thread.new do
				@logger.info "Storing to #{contact}..."
				store(contact, key, value)
			end
		end
	end


	def iterative_find_value(key_hash)
		if @data_store.include?(key_hash) then
			kvalue = @data_store[key_hash] #TODO: Timeouts
			@logger.info "found value on local node. Returning `#{key_hash}` => `#{kvalue}`"
			return {found: true, key: key_hash, value: kvalue} 
		end


		result = iterative_find_node(key_hash, true)
		@logger.info "Result of iterative_find_value: `#{result}`"
		return nil if result.empty? || result.kind_of?(Array)
		return result["value"]
	end

	#if @@tRefresh has passed for a certain bucket, call this
	def do_refresh(bucket_id)
		random_num = rand(bucket_id**2..(bucket_id+1)**2)
		iterative_find_node(random_num)
	end

	def join_network
		# TODO: insert values of known nodes
		close_contacts = iterative_find_node(@node_id)
		close_contacts.each do |contact|
			@bucket_list << contact
		end
	end


	#private
	
	def save_closest_contact(contacts, key_hash)
		if contacts.empty? then
			return []
		end
		@logger.info "saving closest contact: `#{contacts.inspect}`"
		#@logger.info contacts

		closest_node = contacts.first
		closest_distance = calc_distance(closest_node.node_id, key_hash)
		contacts.each do |c|
			distance = calc_distance(c.node_id, key_hash)
			if distance < closest_distance then
				closest_node = c
				closest_distance = distance
			end
		end
		return [closest_node, closest_distance]
	end

	#calculates the distance between two hashes: This can both be used between two nodes, a node and a to-be-stored-or-read value or two values.
	def calc_distance(hasha, hashb)
		return hash_as_num(hasha) ^ hash_as_num(hashb) 
	end

	#Changes a hash in string representation to a Bignum.
	def hash_as_num(hexencoded_hash)
		$digest_class.to_num(hexencoded_hash)
	end

	#Sorts buckets, newest contacts drop to the bottom. (older contacts are preferred to talk with)
	# def sort_bucket_contacts(bucketnum)
	# 	@bucket_list[bucketnum].sort! {|a,b| a.last_contact_time <=> b.last_contact_time }
	# end

	#adds a certain KademliaContact to the correct bucket.
	# def add_contact_to_buckets(contact)
	# 	index = bucket_for_hash(contact.node_id)
	# 	@bucket_list[index].push contact
	# end

	#Returns the bucket index to work on for a given hash
	def bucket_for_hash(hash)
		distance = calc_distance(@node_id, hash)
			@bucket_list.each_with_index do |bucket, j|
			if 2**j <= distance && distance < 2**(j+1) then
				return j
			end
		end
		return @bucket_list.length-1
	end
end