class DistributedHashTree
	attr_accessor :lht, :hash_class

	def initialize
		@hash_class = Digest::SHA2
		@lht = LocalHashTable.new(@hash_class)
	
		@skip_amount_of_empties = 0
	end

	def iterative_hash(iteration_step_algorithm,starting_key)
		iterated_key = starting_key
		loop do
			iterated_key = iteration_step_algorithm.call(iterated_key)
			yield iterated_key
		end
	end



	def conflict_copies(key)
		iterated_key = key
		values = []
		skipped_elements = 0
		iterative_hash(->(hash){@hash_class.digest(hash)}, key) do |iterated_key|
			fetched_value = @lht.fetch(iterated_key)
			if fetched_value.nil?
				skipped_elements += 1
				if skipped_elements >= @skip_amount_of_empties
					break
				end
			else
				values << fetched_value
			end
		end
		return values
	end

	def dir_b_list(key,salt)
		iterated_key = key
		values = []
		skipped_elements = 0
		iterative_hash(->(hash){@hash_class.digest(hash)+salt}, key) do |iterated_key|
			fetched_value = @lht.fetch(iterated_key)
			if fetched_value.nil?
				skipped_elements += 1
				if skipped_elements >= @skip_amount_of_empties
					break
				end
			else
				values << fetched_value
			end
		end
		return values
	end



	# def lookup_tree(key)
	# 	root_nodes = fetch_siblings(key)
	# 	tree = root_nodes.map do |node|
	# 		{
	# 			node: node[:value],
	# 			children: lookup_tree(node[:key])
	# 		}
	# 		#TODO: More than one level of recursion.
	# 	end
	# 	return tree
	# end

	# def fetch_siblings(parent_key)
	# 	nonce = 0
	# 	sibling_key = @hash_class.digest("#{parent_key}#{nonce}").to_sym
	# 	siblings = []
	# 	while(next_sibling = @lht.fetch(sibling_key)) do
	# 		siblings << next_sibling
	# 		nonce += 1
	# 		sibling_key = @hash_class.digest("#{parent_key}#{nonce}").to_sym
	# 	end
	# 	return siblings
	# end

	# def fetch_child(key)
	# 	child_key = @hash_class.digest("#{key}0").to_sym
	# 	return @lht.fetch(child_key)
	# end

	# def store_child(key, value)
	# 	child_key = @hash_class.digest("#{key}0").to_sym
	# 	return @lht.store(child_key, value)
	# end

	# def store_sibling(parent_key, value, nonce=0)
		
	# 	#Increment the nonce until an empty place is found.
	# 	sibling_key = ""
	# 	loop do
	# 		sibling_key = @hash_class.digest("#{parent_key}#{nonce}").to_sym
	# 		nonce += 1
	# 		break unless @lht.fetch(sibling_key)
	# 	end
		
	# 	return @lht.store(sibling_key, value)
	# end
end


# dht = DistributedHashTree.new
# root_key = "test"
# parent = dht.store_sibling(root_key, "abc")
# puts parent
# dht.store_sibling(parent[:key], "def")
# dht.store_sibling(root_key, "ghi")
# dht.store_sibling(parent[:key], "jkl")
# puts dht.inspect
# puts dht.lookup_tree(root_key)