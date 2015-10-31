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
		middle = self.start_num  + (self.end_num-self.start_num)/2
		
		lower_contacts, higher_contacts = self.contacts.partition {|c| $digest_class.to_num(c.node_id) < middle}

		lower =  KademliaBucket.new(self.start_num, middle,{max_bucket_size: self.max_size}, lower_contacts)
		higher = KademliaBucket.new(middle, self.end_num,  {max_bucket_size: self.max_size}, higher_contacts)


		return [lower,higher]
	end
end