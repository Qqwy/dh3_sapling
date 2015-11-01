require 'pathname'
require 'fileutils'

#Could maybe improved with Bloom filter.
class HashTable

	attr_reader :root_path, :tRefresh

	def initialize(root_path, tRefresh=1)
		@root_path = Pathname.new(root_path) #Key/values are stored in this folder. Relative path to current directory.
		@tRefresh = tRefresh #amount of seconds until values should be refreshed.
	end

	def fetch(key)
		file_path  = key_to_path(key)

		return nil unless File.exists? file_path

		return File.binread file_path
	end

	def [](key)
		self.fetch(key)
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

		FileUtils.mkpath(file_path.dirname)
		File.open(file_path, 'wb') do |f|
			f.write(value)
		end
		return used_key
	end

	def []=(key, value)
		self.store(key, value)
	end

	def key_to_path(key)
		#store hash "abcdefghijklmnop" in `op/abcdefghijklmn`
		#Split is this way, as nodes will mostly store keys with a small XOR-distance (which means the high bits are most of the time the same)
		file_name = key[0..-3]
		folder_name = key[-2..-1]

		return @root_path.join(folder_name, file_name)
	end

	def path_to_key(path)
		last_part = path.dirname.to_s
		first_part = path.basename.to_s
		return first_part + last_part
	end


	def exists?(key)
		File.exists? key_to_path(key)
	end

	def include?(key)
		self.exists?(key)
	end

	#Should be called with a block.
	#Runs the block with a {key: key, value: value} hash
	#for each k/v that has been stored longer than @tRefresh seconds ago (and thus should be refreshed).
	#If block has a truth-ey outcome, the value's timestamp is then updated, which means that it will take @tRefresh seconds again before re-appearing in this list.
	#
	#The function returns 'true' if any values have been refreshed, false otherwise.
	def values_to_refresh
		newer_than = Time.now - @tRefresh
		change_happened = false
		Dir[@root_path.join("*/*")].each do |e|
			unless File.directory? e #Skip directories
				puts "File: #{e}"
				if File.mtime(e) < newer_than
					result = yield({key: path_to_key(Pathname.new(e)), value: File.binread(e)})
					if result
						FileUtils.touch(e)
						change_happened = true
					end
				end
			end
		end
		return change_happened
	end

end


def digest(hash)
	require 'digest/sha2'
	return Digest.hexencode Digest::SHA2.digest(hash)
end