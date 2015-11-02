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
	def initialize(identifier, host, port, path="/", config_location, known_nodes=[])

		@logger = Logger.new(STDOUT)
		@logger.level = Logger::DEBUG
		@logger.progname = "`#{identifier}`"


		
		self.read_config(config_location)


		@identifier = identifier.to_s
		@node_id = $digest_class.digest @identifier
		@data_store = HashTable.new("data_store/#{identifier}") #Value Store, keys are hash digests of the values.

		# Refreshes contents of the datastore by re-broadcasting values every tRefresh seconds.
		@scheduler = Thread.new do
			loop do
				@logger.info "Running tRefresh schedule now!"
				@data_store.values_to_refresh do |kv_hash|
					iterative_store(kv_hash[:key], kv_hash[:value])
				end
				@logger.info "Starting scheduler sleep."
				sleep 60
			end
		end



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

	def read_config(config_location)
		require 'yaml'
		@config_location = config_location
		config = YAML.load_file(config_location) || {}

		if config[:public_key].nil? && config[:signature].nil? && config[:single_use_key].nil? && config[:node_id].nil?
			create_node_id(config)
		elsif config[:public_key].nil? || config[:signature].nil? || config[:single_use_key].nil? || config[:node_id].nil?
			#TODO: check signature.
			throw KademliaCorruptedConfigError
		end 
	end

	def create_node_id(config)
		if !config[:private_key].nil?
			throw KademliaCorruptedConfigError
		end
		if config[:address].nil?
			throw KademliaNoAddressInConfigError
		end

		require 'ecdsa'
		require 'securerandom'
		group = ECDSA::Group::Secp256k1
		private_key = 1 + SecureRandom.random_number(group.order - 1)
		puts 'private key: %#x' % private_key

		public_key_point = group.generator.multiply_by_scalar(private_key)
		puts 'public key: '
		puts '  x: %#x' % public_key_point.x
		puts '  y: %#x' % public_key_point.y

		public_key = ECDSA::Format::PointOctetString.encode(public_key_point, compression: true)


		require 'digest/sha2'
		message = config[:address]
		digest = Digest::SHA2.digest(message)
		signature = nil
		while signature.nil?
		  single_use_key = 1 + SecureRandom.random_number(group.order - 1)
		  signature_point = ECDSA.sign(group, private_key, digest, single_use_key)
		end
		puts 'signature: '
		puts '  r: %#x' % signature_point.r
		puts '  s: %#x' % signature_point.s

		signature= ECDSA::Format::SignatureDerString.encode(signature_point)

		node_id = $digest_class.digest(signature)

		config[:private_key] = private_key
		config[:public_key] = public_key
		config[:signature] = signature
		config[:node_id] = node_id
		File.open(@config_location, 'w') do |f| 
			f.write(config.to_yaml) 
		end
	end

	def valid_node_id?(address, public_key, signature, node_id)
		require 'ecdsa'
		group = ECDSA::Group::Secp256k1
		public_key_point = ECDSA::Format::PointOctetString.decode(public_key, group)
		digest = Digest::SHA2.digest(address)
		signature_point = ECDSA::Format::SignatureDerString.decode(signature)
		ECDSA.valid_signature?(public_key_point, digest, signature) && node_id == $digest_class.digest(signature)
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
			c.store(self.to_contact, key, value)
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
			hashed_contacts = c.find_node(self.to_contact, key_hash)
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
			result = c.find_value(self.to_contact, key_hash)
		end
		return result
	end

	def handle_find_value(key_hash)
		@logger.info "`handle_find_value` called with key_hash=`#{key_hash}`"


		if @data_store.include?(key_hash)
			kvalue = @data_store[key_hash] #TODO: Timeouts
			@logger.info "found value on this node. Returning `#{key_hash}` => `#{kvalue.inspect}`"
			return {"found"=> true, "key"=> key_hash, "value"=> kvalue} 
		else
			@logger.info "value for `#{key_hash}` not found. Returning closest nodes."
			return {"found"=> false, "closest_nodes"=> handle_find_node(key_hash)}
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
			if contact.node_id == self.node_id
				next
			end

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
			return {"found"=> true, "key"=> key_hash, "value"=> kvalue} 
		end


		result = iterative_find_node(key_hash, true)
		@logger.info "Result of iterative_find_value: `#{result}`"
		return nil if result.empty? || result.kind_of?(Array)

		self.handle_store(key_hash, result["value"])

		return result
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
		contacts -= [self.to_contact]
		@logger.info "saving closest contacts: `#{contacts.inspect}`"
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

	def add_or_update_contact(contact_info)
		contact = KademliaContact.from_hash(contact_info)
		self.bucket_list.add_or_update_contact(contact)
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