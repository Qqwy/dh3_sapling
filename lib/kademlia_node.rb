#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

require 'rest_client'

class KademliaNode
	@@alpha = 3		# degree of paralellism in network calls
	@@B = 256 		# length of a SHA256 digest
	@@k = 20 		# maximum number of stored contacts.

	@@tExpire = 86500 		#time after which a key/value pair expires. Time To Live from *original* publication date. Note that this is significantly longer than tRepublish to prevent a race condition.
	@@tRefresh = 3600 		#time after which an otherwise unaccessed bucket must be refreshed.
	@@tReplicate = 3600 	#Interval between republication events, when a node is required to publish its entire database.
	@@tRepublish = 86400 	#time after which the original publisher must republish a key/value pair for it not to disappear.



	attr_accessor :node_id, :identifier, :store, :contact_buckets

	#identifier is used to determine the node ID. Should be a quasi-random number.
	def initialize(identifier, known_nodes=[])
		@identifier = identifier
		@node_id = $digest_class.digest identifier
		@store = {} #Value Store, keys are hash digests of the values.

		 # Buckets of contacts. 
		 # for bucket j, where 0 <= j <= k, 2^j <= calc_distance(node.node_id, contact.node_id) < 2^(j+1) 
		@contact_buckets = (0...@@k).collect {[]}

		known_nodes.each do |contact|
			add_contact_to_buckets(contact)
		
		end
		#run_event_machine

	end

	def ping(contact)
		contact.client.ping
	end

	def handle_ping
		puts "returning pong to ping"
		return "pong"
	end

	#Primitive operation to require contact to store data.
	def store(contact, key, value)
		contact.client.store(key,value)
	end

	def handle_store(key, value)
		@store[key] = value
		puts "Storing `#{key}` => `#{value}`)"
		return true
	end

	#Primitive operation to require contact to return up to @@k KademliaContacts closest to given key
	def find_node(contact, key_hash)
		json_contacts = contact.client.find_node(key_hash)
		json_contacts.map{|json_contact| KademliaContact.from_hash(json_contact)}
	end

	def handle_find_node(key_hash)
		sorted_contacts = @contact_buckets.flatten.sort {|a,b| self.calc_distance(key_hash,a.node_id) <=> self.calc_distance(key_hash,b.node_id)}
		puts "Returning closest nodes:"
		puts sorted_contacts.inspect
		return sorted_contacts.take(@@k).map {|contact| contact.to_json}
	end

	#Primitive operation to ask contact to return either:
	# => the value for the specific key_hash, if he has it.
	# => if not, return the result of `#find_node` (closest contacts that might know it)
	def find_value(contact, key_hash)
		contact.client.find_value(key_hash)
	end

	def handle_find_value(key_hash)
		if @store.include?(key_hash) then
			puts "found value on this node. Returning `#{key_hash}` => `#{@store[key_hash]}`"
			return {found: true, key: key_hash, value: @store[key_hash]} 
		end
		puts "value for `#{key_hash}` not found. Returning closest nodes."
		return {found: false, closest_nodes: handle_find_node(key_hash)}
	end

	#Iterative node lookup.
	def iterative_find_node(key_hash, use_find_value=false)
		shortlist_index = bucket_for_hash(key_hash)
		shortlist = @contact_buckets[shortlist_index]
		closest_node, closest_distance = save_closest_contact(shortlist, key_hash)
		already_contacted_contacts = []
		probed_contact_amount = 0

		#TODO: Paralellism using @@alpha

		shortlist.each do |contact|
			if use_find_value then
				result = find_value(contact, key_hash)
				puts result
				if result["found"] then
					#Save result in closest node that did *not* return the value
					store(closest_node, key_hash, result["value"])

					return result
				else
					new_shortlist = result["closest_nodes"]
					puts new_shortlist
				end
			else
				new_shortlist = find_node(contact, key_hash)
			end
			already_contacted_contacts << contact
			shortlist += new_shortlist

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
		return shortlist.sort {|a,b| calc_distance(a.node_id, key_hash) <=> calc_distance(b.node_id, key_hash)}.take(@@k)
	end

	def iterative_store(key, value)
		contact = iterative_find_node(key)
		store(contact, key, value)
	end


	def iterative_find_value(key)
		result = iterative_find_node(key, true)
		return result["value"]
	end

	#if @@tRefresh has passed for a certain bucket, call this
	def do_refresh(bucket_id)
		random_num = rand(bucket_id**2..(bucket_id+1)**2)
		iterative_find_node(random_num)
	end

	def join_network
		# TODO: insert values of known nodes
		iterative_find_node(@@node_id)
	end


	#private
	
	def save_closest_contact(contacts, key_hash)
		if contacts.empty? then
			return []
		end

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
	def hash_as_num(hash)
		hash.bytes.inject {|a, b| (a << 8) + b }
	end

	#Sorts buckets, newest contacts drop to the bottom. (older contacts are preferred to talk with)
	def sort_bucket_contacts(bucketnum)
		@contact_buckets[bucketnum].sort! {|a,b| a.last_contact_time <=> b.last_contact_time }
	end

	#adds a certain KademliaContact to the correct bucket.
	def add_contact_to_buckets(contact)
		index = bucket_for_hash(contact.node_id)
		@contact_buckets[index].push contact
	end

	#Returns the bucket index to work on for a given hash
	def bucket_for_hash(hash)
		distance = calc_distance(@node_id, hash)
			@contact_buckets.each_with_index do |bucket, j|
			if 2**j <= distance && distance < 2**(j+1) then
				return j
			end
		end
		return @contact_buckets.length-1
	end
end