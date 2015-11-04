require 'rest_client'
require 'rack/rpc'

module Sapling
	class Node < Rack::RPC::Server
		@@alpha = 3		# degree of paralellism in network calls
		@@B = 256 		# number of bits in a SHA256 digest, e.g. 256.
		@@k = 8 		# maximum number of stored contacts per bucket.

		@@tExpire = 86500 		#time after which a key/value pair expires. Time To Live from *original* publication date. Note that this is significantly longer than tRepublish to prevent a race condition.
		@@tRefresh = 3600 		#time after which an otherwise unaccessed bucket must be refreshed.
		@@tReplicate = 3600 	#Interval between republication events, when a node is required to publish its entire database.
		@@tRepublish = 86400 	#time after which the original publisher must republish a key/value pair for it not to disappear.



		attr_accessor :node_id, :data_store, :bucket_list, :server, :logger
		attr_reader :config

		def initialize(config_location, known_addresses=[])

			@logger = Logger.new(STDOUT)
			@logger.level = Logger::INFO


			
			self.read_config(config_location)

			@address = @config[:address]
			@public_key = @config[:public_key]
			@signature = @config[:signature]
			@bcrypt_salt = @config[:bcrypt_salt]
			@node_id = @config[:node_id]
			@logger.progname = "`#{self.node_id[0..3]}...#{self.node_id[-4..-1]}<->#{@address}`"


			@data_store = HashTable.new("data_store/#{self.node_id}") #Value Store, keys are hash digests of the values.

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
			@bucket_list = Sapling::BucketList.new(self.node_id, {max_bucket_size:@@k})

			known_addresses.each do |address|
				self.ping Sapling::Contact.new("", address)	
			end


			#@server = SaplingServer.new(self, @address)

			#Besides the known_addresses above, find out nodes that are close in the XOR-metric distance, and add them.
			self.join_network

		end

		def read_config(config_location)
			require 'yaml'
			@config_location = config_location
			config = YAML.load_file(config_location) || {}

			if config[:public_key].nil? && config[:signature].nil? && config[:bcrypt_salt].nil? && config[:node_id].nil? 
				create_node_id(config)
			elsif config[:public_key].nil? || config[:signature].nil? || config[:bcrypt_salt].nil? || config[:node_id].nil?
				#TODO: check signature.
				throw Sapling::CorruptedConfigError
			elsif !valid_node_id?(config[:address], config[:public_key], config[:signature], config[:bcrypt_salt], config[:node_id])
				throw Sapling::CorruptedConfigError
			else
				@logger.unknown "Loading Config File Finished. Node ID: `#{config[:node_id]}`"
			end
			@config = config 
		end

		def create_node_id(config)
			require 'ecdsa'
			require 'securerandom'
			require 'bcrypt'

			#Allow manually setting a private key, when this is copied over from an earlier node instance (possibly hosted elsewhere)
			#Obviously, this should be a large random integer number, > 0.
			if !config[:private_key].nil? && config[:private_key].to_i == 0
				throw Sapling::CorruptedConfigError
			end
			if config[:address].nil?
				throw Sapling::NoAddressInConfigError
			end

			@logger.unknown "Constructing Node ID for `#{config[:address]}`"
			@logger.unknown "Generating Private Key..."
			address = config[:address]

			group = ECDSA::Group::Secp256k1
			private_key = 1 + SecureRandom.random_number(group.order - 1)

			@logger.unknown "Generating Public Key..."

			public_key_point = group.generator.multiply_by_scalar(private_key)
			public_key = ECDSA::Format::PointOctetString.encode(public_key_point, compression: true)

			@logger.unknown "Generating Signature..."

			digest = Sapling.digest_class.digest(address)
			signature_point = nil
			while signature_point.nil?
			  single_use_key = 1 + SecureRandom.random_number(group.order - 1)
			  signature_point = ECDSA.sign(group, private_key, digest, single_use_key)
			end

			@logger.unknown "Hashing Signature to form Node ID..."

			signature = ECDSA::Format::SignatureDerString.encode(signature_point)
			bcrypt_salt = BCrypt::Engine.generate_salt(10)

			bcrypted_signature = BCrypt::Engine.hash_secret(signature, bcrypt_salt)

			node_id = Sapling.digest_class.digest(bcrypted_signature)

			@logger.unknown "Writing to Config File..."


			config[:private_key] = private_key
			config[:public_key] = public_key
			config[:signature] = signature
			config[:bcrypt_salt] = bcrypt_salt
			config[:node_id] = node_id




			File.open(@config_location, 'w') do |f| 
				f.write(config.to_yaml) 
			end

			@logger.unknown "Finished. Node ID: `#{config[:node_id]}`"
		end

		def valid_node_id?(address, public_key, signature, bcrypt_salt, node_id)
			require 'ecdsa'
			require 'bcrypt'
			group = ECDSA::Group::Secp256k1
			public_key_point = ECDSA::Format::PointOctetString.decode(public_key, group)
			digest = Sapling.digest_class.digest(address)
			signature_point = ECDSA::Format::SignatureDerString.decode(signature)
			test_node_id = Sapling.digest_class.digest(BCrypt::Engine.hash_secret(signature, bcrypt_salt))

			ECDSA.valid_signature?(public_key_point, digest, signature_point) && node_id == test_node_id
		end

		def to_contact
			Sapling::Contact.new(@node_id, @address, @public_key, @signature, @bcrypt_salt)
		end

		def ping(contact)
			@logger.info "Calling RPC `ping` on #{contact.name}"
			begin
				contact.client do |c|
					updated_contact_info = c.ping(self.to_contact)
					add_or_update_contact(updated_contact_info)
				end
			rescue Sapling::ClientConnectionError
				@logger.info "ping: Disregard contact #{contact.name} because of a Connection Error"
			end

		end

		def handle_ping
			@logger.info "ping received. Returning contact info"
			return self.to_contact
		end

		#Primitive operation to require contact to store data.
		def store(contact, key, value)
			@logger.info "Calling RPC `store` on #{contact.name}"
			actual_key = nil
			begin
				contact.client do |c|
					actual_key = c.store(self.to_contact, key, value)
					@logger.info "Value stored. Reference key: `#{actual_key}`"
				end
			rescue Sapling::ClientConnectionError
				@logger.info "store: Value not stored on #{contact.name} because of a Connection Error"
			end
			return actual_key
		end

		def handle_store(key, value)
			#key = Sapling.digest_class.digest value
			actual_key = @data_store.store(key, value)
			@logger.info "Storing `#{actual_key}` => `#{value}`) on locally"
			return actual_key
		end

		#Primitive operation to require contact to return up to @@k Sapling::Contacts closest to given key
		def find_node(contact, key_hash)
			@logger.info "Calling RPC `find_node` on #{contact.name}"
			begin
				contact.client do |c| 
					hashed_contacts = c.find_node(self.to_contact, key_hash)
					result = hashed_contacts.map{|hashed_contact| Sapling::Contact.from_hash(hashed_contact)}
					return result
				end
			rescue Sapling::ClientConnectionError
				@logger.info "find_node: Disregard contact #{contact.name} because of a Connection Error"
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
			begin
				contact.client do |c|
					@logger.info "Calling RPC `find_value` on #{contact.name}"
					result = c.find_value(self.to_contact, key_hash)
				end
			rescue Sapling::ClientConnectionError
				@logger.info "find_value: Disregard contact #{contact.name} because of a Connection Error"
			end
			return result
		end

		def handle_find_value(key_hash)
			@logger.debug "`handle_find_value` called with key_hash=`#{key_hash}`"


			if @data_store.include?(key_hash)
				kvalue = @data_store[key_hash] #TODO: Timeouts
				@logger.info "found value locally. Returning `#{key_hash}` => `#{kvalue.inspect}`"
				return {"found"=> true, "key"=> key_hash, "value"=> kvalue} 
			else
				@logger.info "value for `#{key_hash}` not locally found. Returning closest nodes."
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
				if already_contacted_contacts.include?(contact) || contact.node_id == self.node_id
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
							new_shortlist = result["closest_nodes"].map{|hashed_contact| Sapling::Contact.from_hash(hashed_contact)}
							@logger.info new_shortlist
						end
					else
						new_shortlist = find_node(contact, key_hash)
					end
				rescue Sapling::ClientConnectionError => e
					@logger.info "Contact #{contact.name} did not respond to `find_*` RPC. Skip to next."
					next #In the case of an error connecting to a contact, skip to the next one in the shortlist.
				end
				already_contacted_contacts << contact
				
				shortlist += new_shortlist #add all new contacts


				new_closest_node, new_closest_distance = save_closest_contact(new_shortlist, key_hash)
				if !new_closest_distance.nil? && new_closest_distance < closest_distance then
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
			#key = Sapling.digest_class.digest value
			result_key = self.handle_store(key, value) #Also store locally, as there is a high possibility that it will be re-requested by uploader.
			
			closest_contacts = iterative_find_node(key)
			closest_contacts.each do |contact|
				Thread.new do
					@logger.info "Storing to #{contact.name}..."
					store(contact, key, value)
				end
			end
			return {"stored"=> true, "key"=> result_key, "value"=> value}
		end


		def iterative_find_value(key_hash)
			if @data_store.include?(key_hash) then
				kvalue = @data_store[key_hash] #TODO: Timeouts
				@logger.debug "found value on local node. Returning `#{key_hash}` => `#{kvalue}`"
				return {"found"=> true, "key"=> key_hash, "value"=> kvalue} 
			end


			result = iterative_find_node(key_hash, true)
			@logger.debug "Result of iterative_find_value: `#{result}`"
			return {"found"=> false, "key"=> key_hash}  if result.empty? || result.kind_of?(Array)

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
			contacts.reject! {|c| c.node_id == self.node_id} #The local node should never be considered closest.
			if contacts.empty? then
				return []
			end
			@logger.info "saving closest contacts: `#{contacts.map(&:name)}` vs `#{self.to_contact.name}`"
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
			contact = Sapling::Contact.from_hash(contact_info)
			if valid_node_id?(contact.address, contact.public_key, contact.signature, contact.bcrypt_salt, contact.node_id)
				self.bucket_list.add_or_update_contact(contact)
			else
				logger.warn "Rejected adding/updating contact `#{contact.inspect}` because of invalid node_id."
			end
		end

		#calculates the distance between two hashes: This can both be used between two nodes, a node and a to-be-stored-or-read value or two values.
		def calc_distance(hasha, hashb)
			return hash_as_num(hasha) ^ hash_as_num(hashb) 
		end

		#Changes a hash in string representation to a Bignum.
		def hash_as_num(hexencoded_hash)
			Sapling.digest_class.to_num(hexencoded_hash)
		end



		def contacts
			@bucket_list.contacts
		end



		#Rack-RPC part
		public

		# Two types of method:
		# n2n => Node to Node contact. Updates information at one node with information of other.
		# ep => endpoint. Called from another app that wants to use the resources, but is not a node itself.
		#       Note that some functionality is not available here, as some primitive requests (find_node, store) are not supposed to be made by endpoints.
		# A local object (another Rack app, e.g. Rails, etc.) can of course call the `ep_*` commands directly as well.


		def n2n_ping(contactor_info) #@s.add_handler('kademlia.ping') do |contactor_info|
			self.add_or_update_contact contactor_info
			self.handle_ping.to_hash
		end

		def ep_ping
			self.handle_ping.to_hash
		end
		
		def n2n_store(contactor_info, key, value) #@s.add_handler('kademlia.store') do |contactor_info, key, value|
			self.add_or_update_contact contactor_info
			self.handle_store(key, value)
		end

		def ep_store(key, value)
			self.iterative_store(key, value)
		end
		
		def n2n_find_node(contactor_info, key_hash) #@s.add_handler('kademlia.find_node') do |contactor_info, key_hash| 
			self.add_or_update_contact contactor_info
			self.handle_find_node(key_hash)
		end

		def ep_find_close_nodes(key_hash)
			self.iterative_find_node(key_hash).map(&:to_hash)
		end
		
		def n2n_find_value(contactor_info, key_hash) #@s.add_handler('kademlia.find_value') do |contactor_info, key_hash| 
			self.add_or_update_contact contactor_info
			self.handle_find_value(key_hash)
		end

		def ep_find_value(key_hash)
			self.iterative_find_value(key_hash)
		end

		rpc 'n2n_ping' => :n2n_ping
		rpc 'n2n_store' => :n2n_store
		rpc 'n2n_find_node' => :n2n_find_node
		rpc 'n2n_find_value' => :n2n_find_value


		rpc 'ep_ping' => :ep_ping
		rpc 'ep_store' => :ep_store
		rpc 'ep_find_close_nodes' => :ep_find_close_nodes
		rpc 'ep_find_value' => :ep_find_value

		
	end
end