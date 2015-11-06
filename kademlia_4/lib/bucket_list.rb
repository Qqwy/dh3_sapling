module Sapling
	class BucketList

		attr_reader :buckets, :node_id, :contacts_store_location
		def initialize(node_id, contacts_store_location, settings)
			@node_id = node_id
			@contacts_store_location = Pathname.new(contacts_store_location)
			@buckets = YAML.load_file(contacts_store_location) || [Sapling::Bucket.new(0, Sapling.digest_class.hash_size, settings)]
		end


		def <<(contact)

			$logger.info "Attempting to add contact to buckets list: `#{contact.name}`"

			# Never add yourself (or an impersonator).
			if contact.node_id == self.node_id
				return false 
			end

			bucket = self.find_bucket_for(contact.node_id)
			if bucket.nil?
				raise Sapling::BucketNotFoundError
			end

			return unless bucket << contact

			if bucket.full?
				# TODO: Check if current node itself is contained.
				if bucket.contains? node_id
					bucket_index = self.buckets.index(bucket)
					self.buckets[bucket_index..bucket_index] = bucket.split! # I love this language (-:
				else
					bucket.refresh!
				end
			end
		end

		def add_or_update_contact(contact)
			if index = self.contacts.index(contact) 
				$logger.info "Updating Contact: #{contact.name}"
				self.contacts[index].update_contact_time!
			else
				#Verification is only necessary once: When seeing a new contact.
				if !Sapling::Contact.valid_node_id?(contact.address, contact.public_key, contact.signature, contact.bcrypt_salt, contact.node_id)
					logger.warn "Rejected adding/updating contact `#{contact.inspect}` because of invalid node_id."
				else
					$logger.info "Storing new Contact: #{contact.name}"
					self << contact
				end
			end

			save_contacts_to_file
		end

		def find_bucket_for(hash)
			self.buckets.each do |bucket|
				if bucket.contains? hash
					return bucket
				end
			end
		end

		#TODO: Find out if necessary to grab other buckets if not enough contacts?
		def closest_contacts(hash)
			return find_bucket_for(hash).contacts
		end

		def contacts
			self.buckets.map(&:contacts).flatten
		end

		def persist_contacts
			FileUtils.mkpath(@contacts_store_location.dirname)

			File.open(@contacts_store_location, 'w') do |f|
				f.write(self.buckets.to_yaml)
			end
		end
		

	end
end