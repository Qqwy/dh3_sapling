#A node in the iterated-directions-tree, that does not contain a parse-able value
class EmptyTreeNode < TreeNode

	attr_reader :key, :value, :nil_reason
	def initialize(hash_class, key, value, nil_reason=nil)
		super(key, value)
		@nil_reason = nil_reason
	end
end