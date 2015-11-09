require 'digest/sha2'


class LocalHashTable
	
	def initialize(hash_class)
		@table = {}
		@hash_class = hash_class
	end

	def store(key, value)
		symkey = key.to_sym
		while (fetched_value = fetch(symkey)) do #Skip to the next conflict-param hash until the value can be inserted.
			if value == fetched_value[:value]
				return #Value already stored.
			else
				symkey = @hash_class.digest("#{symkey}CONFLICT").to_sym
			end
		end
		@table[symkey] = value
		return {key: key, value: @table[symkey]}
	end

	def fetch(key)
		symkey = key.to_sym
		return nil unless @table.include? symkey
		return {key: key, value: @table[symkey]}
	end
end


class DistributedHashTree
	attr_accessor :lht

	def initialize
		@hash_class = Digest::SHA2
		@lht = LocalHashTable.new(@hash_class)
	end

	def lookup_tree(key)
		root_nodes = fetch_siblings(key)
		tree = root_nodes.map do |node|
			{
				node: node[:value],
				children: lookup_tree(node[:key])
			}
			#TODO: More than one level of recursion.
		end
		return tree
	end

	def fetch_siblings(parent_key)
		nonce = 0
		sibling_key = @hash_class.digest("#{parent_key}#{nonce}").to_sym
		siblings = []
		while(next_sibling = @lht.fetch(sibling_key)) do
			siblings << next_sibling
			nonce += 1
			sibling_key = @hash_class.digest("#{parent_key}#{nonce}").to_sym
		end
		return siblings
	end

	def fetch_child(key)
		child_key = @hash_class.digest("#{key}0").to_sym
		return @lht.fetch(child_key)
	end

	def store_child(key, value)
		child_key = @hash_class.digest("#{key}0").to_sym
		return @lht.store(child_key, value)
	end

	def store_sibling(parent_key, value, nonce=0)
		
		#Increment the nonce until an empty place is found.
		sibling_key = ""
		loop do
			sibling_key = @hash_class.digest("#{parent_key}#{nonce}").to_sym
			nonce += 1
			break unless @lht.fetch(sibling_key)
		end
		
		return @lht.store(sibling_key, value)
	end
end


dht = DistributedHashTree.new
root_key = "test"
parent = dht.store_sibling(root_key, "abc")
puts parent
dht.store_sibling(parent[:key], "def")
dht.store_sibling(root_key, "ghi")
dht.store_sibling(parent[:key], "jkl")
puts dht.inspect
puts dht.lookup_tree(root_key)