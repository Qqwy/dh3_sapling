class TreeNode

	attr_reader :key, :value
	def initialize(key, value)
		@key = key
		@value = value
	end

	def next_keys(directions)
		directions.map do |d|
			d.key = self.key
			d.next_key
		end
	end
end