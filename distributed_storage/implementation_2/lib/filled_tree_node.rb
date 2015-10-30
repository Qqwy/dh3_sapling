class FilledTreeNode < TreeNode

	attr_reader :key, :data, :reference, :label, :signature

	attr_accessor :collection
	def initialize(key, value, data, reference, label, signature, collection={})
		super(key, value)
		@data = data
		@reference = reference
		@label = label
		@signature = signature

		@collection = collection
	end

	def children
		collection.values.select{|n| n.reference == self.label}
	end

	def new_child(hash_class, data)
		value = {
			d: data,
			r: self.label,
			l: hash_class.digest({d:data,r:self.label}.to_json),
			s: "TODO"
		}
		new_node = FilledTreeNode.new(
			nil,
			value.to_json,
			value[:d],
			value[:r],
			value[:l],
			value[:s],
			self.collection
		)
		self.collection[value[:l]] = new_node

		return new_node
	end

	def parent
		collection[self.reference]
	end

end