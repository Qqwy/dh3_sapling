class Tree

	attr_accessor :collection, :root_node
	def initialize(hash_class, root_data, root_key = nil)
		@root_node = FilledTreeNode.create_new(hash_class, root_data, root_key)
		@collection = {root_key=>self.root_node}
	end


	def self.from_existing_collection(hash_class, collection, root_node)
		tree = self.new(hash_class, nil, nil)
		tree.root_node = root_node
		tree.collection = root_node.collection

		return tree
	end

	def nodes
		self.collection.values
	end

	def size
		self.collection.size
	end

	def unsaved_nodes
		self.collection.values.reject {|n| n.has_key?}
	end
end