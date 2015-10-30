class TreeTraverser

	attr_reader :hash_class, :dht, :directions

	def initialize(hash_class, dht, directions)
		@hash_class = hash_class
		@dht = dht
		@directions = directions

	end

	def find_nodes(root_key)
		# 1. fetch root node
		queue = [root_node = make_node_from_key(root_key)]
		found_nodes = {}

		# 2. Iterate over queue until empty
		until queue.empty?
			current_node = queue.shift

			puts current_node.inspect

			if current_node.respond_to?(:label)
				found_nodes[current_node.label] = current_node
			else
				puts "Empty Node: #{current_node.inspect}" 
			end

			if current_node.kind_of? EmptyTreeNode
				 # TODO skip over consecutive empty spaces
			else
				self.directions.each do |d|
					d.key = current_node.key
				end
				next_keys = current_node.next_keys(self.directions)
				next_keys.each do |key|
					queue << node = make_node_from_key(key)
				end
			end
		end

		found_nodes
	end


	def build_tree(root_key)
		found_nodes = find_nodes(root_key)
		puts found_nodes
		found_nodes.each { |key,node| node.collection=found_nodes}

		return found_nodes[root_key]
	end


	def save_tree(collection, insert_after_direction)
		new_nodes = collection.values.select{|node| node.key.nil?}

		start_key = insert_after_direction.key
		
		new_nodes.each do |node|
			loop do
				key = insert_after_direction.next_key
				if self.dht.fetch(key).nil?
					dht.store(key, node.value)
					break
				end
			end
		end

		insert_after_direction.key = start_key #Reset to be ready to re-read table from this point TODO?
		return true
	end

	def make_node_from_key(key)
		value = self.dht.fetch(key)
		if value.nil?
			 # TODO: skip over N consecutive empty spaces
			return EmptyTreeNode.new(key, nil, "Value not found")
		else
			begin

				json_value = JSON.parse(value[:value], symbolize_names: true)
				#TODO: Verify signature here?
				return FilledTreeNode.new(key, value[:value], json_value[:d], json_value[:r], json_value[:l], json_value[:s])
			rescue => e
				return EmptyTreeNode.new(key, nil, e)
			end

		end
	end
end