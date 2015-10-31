class KademliaBucketList

	attr_reader :buckets
	def initialize(node_id, settings)
		@node_id = node_id
		@buckets = [KademliaBucket.new(0, $digest_class.hash_size, settings)]
	end


	def add_contact(contact)
		contact_id = contact.node_id
		bucket = self.find_bucket_for(contact_id)
		if bucket.full?
			# TODO: Check if current node itself is contained.
			if bucket.contains? node_id
				bucket_index = self.buckets.lindex(bucket)
				self.buckets[bucket_index..bucket_index] = bucket.split! # I love this language (-:
			else

			end
		else
			bucket.add_contact(contact)
		end
	end

	def find_bucket_for(hash)
		self.buckets.each do |bucket|
			if bucket.contains? hash
				return bucket
			end
		end
	end
end