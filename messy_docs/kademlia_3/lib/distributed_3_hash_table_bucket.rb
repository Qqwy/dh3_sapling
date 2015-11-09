class Distributed3HashTableBucket
	
	attr_reader :starting_point, :ending_point
	attr_accessor :nodes
	def initialize(starting_point, ending_point, nodes=[])
		@starting_point, @ending_point, @nodes = starting_point, ending_point, nodes

	end

	def should_contain?(hash)
		self.starting_point <= hash_as_num(hash) && self.ending_point > hash_as_num(hash)
	end

	def split
		middle = self.starting_point + ((self.ending_point - self.starting_point)/2)
		lower = Distributed3HashTableBucket.new(self.starting_point, middle)
		higher = Distributed3HashTableBucket.new(middle, self.ending_point)

		lower.nodes =  self.nodes.filter {|n| lower.should_contain?(n.node_id)}
		higher.nodes = self.nodes.filter {|n| higher.should_contain?(n.node_id)}

		return [lower,higher]
	end

	#Changes a hash in string representation to a Bignum.
	def hash_as_num(hexencoded_hash)
		[str].pack('H*')
	end
end