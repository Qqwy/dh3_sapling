class EmptyTreeNode < TreeNode

	attr_reader :key, :value, :nil_reason
	def initialize(key, value, nil_reason=nil)
		super(key, value)
		@nil_reason = nil_reason
	end
end