
class LocalHashTable
	
	def initialize(hash_class)
		@table = {}
		@hash_class = hash_class
	end

	def store(key, value)
		while (fetched_value = fetch(key)) do #Skip to the next conflict-param hash until the value can be inserted.
			if value == fetched_value[:value]
				return #Value already stored.
			else
				key = @hash_class.digest(key)
			end
		end
		@table[key] = value
		return {key: key, value: @table[key]}
	end

	def fetch(key)
		return nil unless @table.include? key
		return {key: key, value: @table[key]}
	end
end