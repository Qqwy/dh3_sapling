class KademliaBucket

	attr_reader :start_num, :end_num, :contacts

	def initialize(start_num, end_num, settings, bootstrap_contacts={})
		@start_num = start_num
		@end_num = end_num
		@contacts = []
		@max_size = settings[:max_bucket_size]

		bootstrap_contacts.each do |c|
			self.add_contact c
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
		return (self.start_num..self.end_num).contains?  $digest_class.to_num(hash)
	end

	def full?
		self.contacts.size >= @max_size
	end

	def add_contact(contact)
		@contacts << contact
	end

	def split
		lower_contacts, higher_contacts = self.contacts.partition {|c| $digest_class.to_num(c.node_id) < self.middle_num}

		lower =  KademliaBucket.new(self.start_num, self.middle_num,{max_bucket_size: self.max_size}, lower_contacts)
		higher = KademliaBucket.new(self.middle_num, self.end_num,  {max_bucket_size: self.max_size}, higher_contacts)

		return [lower,higher]
	end

	# Ping all nodes in bucket. Drop non-responding ones.
	def refresh
		self.contacts.reverse_each.with_index do |c,i|
			begin
				c.client do |client|
					updated_contact = client.ping
					#Actually updating contact's last_connect_time happens automatically in KademliaContact#client
				end
			rescue 	Exceptions::KademliaClientConnectionError => e

       			self.contacts.delete(i)
   			end
		end
	end
end