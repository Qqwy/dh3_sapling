module Sapling
	class Bucket

		attr_reader :start_num, :end_num, :contacts

		def initialize(start_num, end_num, settings, bootstrap_contacts={})
			@start_num = start_num
			@end_num = end_num
			@contacts = []
			@max_size = settings[:max_bucket_size]

			bootstrap_contacts.each do |c|
				self << c
			end
		end

		def middle_num
			self.start_num  + (self.end_num-self.start_num)/2
		end


		# Used to refresh a bucket
		def random_within_range
			rand(self.start_num..self.end_num)
		end

		def contains?(hash)
			return (self.start_num..self.end_num).include?  Sapling.digest_class.to_num(hash)
		end

		def size
			@contacts.size
		end

		def full?
			self.size >= @max_size
		end

		def empty?
			self.contacts.empty?
		end

		def <<(contact)
			if @contacts.include? contact 
				return false
			else
				@contacts << contact
				return true
			end
		end

		def split!
			lower_contacts, higher_contacts = self.contacts.partition {|c| Sapling.digest_class.to_num(c.node_id) < self.middle_num}

			lower =  Sapling::Bucket.new(self.start_num, self.middle_num,{max_bucket_size: @max_size}, lower_contacts)
			higher = Sapling::Bucket.new(self.middle_num, self.end_num,  {max_bucket_size: @max_size}, higher_contacts)

			return [lower,higher]
		end

		# Ping all nodes in bucket. Drop non-responding ones.
		def refresh!
			self.contacts.reverse_each.with_index do |contact,i|
				begin
					contact.client do |client|
						client.ping(contact)
						#Actually updating contact's last_connect_time happens automatically in SaplingContact#client
					end
				rescue 	Sapling::ClientConnectionError => e

	       			self.contacts.delete(i)
	   			end
			end
		end

	end
end