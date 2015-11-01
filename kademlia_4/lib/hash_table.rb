require 'pathname'
require 'fileutils'

#Could maybe improved with Bloom filter.
class HashTable

	def initialize(root_path)
		@root_path = Pathname.new(root_path) #Key/values are stored in this folder. Relative path to current directory.
	end

	def fetch(key)
		file_path  = key_to_path(key)

		return nil unless File.exists? file_path

		return File.binread file_path
	end

	#Stores the value using side-stepping.
	#TODO: Isolate re-hashing behaviour to use $digest_class properly.
	def store(key, value)
		used_key = key 
		while File.exists?(key_to_path(used_key))
			if fetch(used_key) == value
				return used_key # Already exists. Do not store again.
			end
			used_key = digest(key)
		end
		file_path = key_to_path(used_key)

		FileUtils.mkpath(file_path.parent)
		File.open(file_path, 'wb') do |f|
			f.write(value)
		end
		return used_key
	end

	def key_to_path(key)
		#store hash "abcdefghijklmnop" in `op/abcdefghijklmn`
		#Split is this way, as nodes will mostly store keys with a small XOR-distance (which means the high bits are most of the time the same)
		file_name = key[0..-3]
		folder_name = key[-2..-1]

		return @root_path.join(folder_name, file_name)
	end


	def exists?(key)
		File.exists? key_to_path(key)
	end

end


def digest(hash)
	require 'digest/sha2'
	return Digest.hexencode Digest::SHA2.digest(hash)
end