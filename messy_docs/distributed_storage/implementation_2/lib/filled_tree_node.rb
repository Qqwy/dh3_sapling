#A node in the iterated-directions-tree, that is parse-able.
class FilledTreeNode < TreeNode

	attr_reader :key, :data, :reference, :label, :signature, :hash_class

	attr_accessor :collection
	def initialize(hash_class, key, value, data, reference=nil, label=nil, signature=nil, collection={})
		@data = data
		@reference = reference
		@signature = signature
		@hash_class = hash_class

		if label.nil?
			label = hash_class.digest({d:data,r:reference}.to_json)
		end
		@label = label

		if value.nil?
			value = {
				d: data,
				r: reference,
				l: label,
				s: signature
			}.to_json
		end

		super(key, value)

		@collection = collection
	end

	def new_child(hash_class, data)
		new_node = FilledTreeNode.create_new(hash_class, data, self.label)
		self.collection[new_node.label] = new_node 
		new_node.collection = self.collection

		return new_node
	end

	# Creates a new node that contains said data.
	# auto-generates all fields that can be inferred.
	def self.create_new(hash_class, data, reference=nil)
		FilledTreeNode.new(
			hash_class,
			nil,
			nil,
			data,
			reference,
			nil,
			"TODO",
			{}
		)
	end

	def has_key?
		return !self.key.nil?
	end

	def children
		collection.values.select{|n| n.reference == self.label}
	end

	def has_children?
		children.any?
	end

	def parent
		collection[self.reference]
	end

	def siblings
		self.parent.children
	end

	def has_siblings?
		siblings.any?
	end

	def ancestors
		ancestor = self
		nodes = []
		while (ancestor = ancestor.parent)
			nodes << ancestor
		end
		nodes
	end

	def root
		([self] + self.ancestors).last
	end

	def is_root?
		self.root == self
	end

	def descendants
		nodes = []
		queue = self.children
		until queue.empty?
			descendant = queue.shift
			queue += descendant.children
			nodes << descendant
		end
		nodes
	end

	def depth
		ancestors.size
	end

	def tree
		Tree.from_existing_collection(self.hash_class, self.collection, self.root)
	end

	# creates a hash where the key is the current node, and the value an array of recursive ancestries of its children
	# When passed a block, will instead return set the key (at each recursive level) to the result of the block (which is called with the specific node as parameter).
	# Example usage: node.ancestry {|n| n.data}
	def ancestry(&block)
		if block_given?
			{block.call(self) => self.children.map {|c| c.ancestry(&block)} }
		else

			{self => self.children.map(&:ancestry)}
		end
	end


end