class KademliaBucketList

	attr_reader :buckets, :node_id
	def initialize(node_id, settings)
		@node_id = node_id
		@buckets = [KademliaBucket.new(0, $digest_class.hash_size, settings)]
	end


	def <<(contact)

		# Never add yourself (or an impersonator).
		if contact.node_id == self.node_id
			return false 
		end

		bucket = self.find_bucket_for(contact.node_id)
		if bucket.nil?
			raise Exceptions::BucketNotFoundError
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


end