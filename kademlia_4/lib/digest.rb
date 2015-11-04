
module Sapling

	class Digest

		def self.hash_length
			raise "Classes that inherit from Digest should specify the `hash_length` method."
		end

		#Hashes a key, returning a SHA3-hash, in urlsafe paddingless Base64 format.
		def self.digest(key)
			raise "Classes that inherit from Digest should specify the `digest(key)` method."
		end

		#Adds all consecutive chars together to find the numerical value of the hash.
		#This numerical value is needed to do XOR calculations.
		def self.to_num(hash_as_str)
			raise "Classes that inherit from Digest should specify the `to_num(hash)` method."
		end

		# Also known as `B` in the Kademlia specification. The number of unique keys that can be constructed using this hashing function.
		def self.hash_size
			2**self.hash_length
		end

	end

	#Helper class that encodes/decodes the urlsafe paddingless Base64 format.
	class UrlsafePaddinglessBase64
		def self.encode(str)
			Base64.encode64(str).tr('+/','-_').gsub(/[\n=]/,'')
		end

		def self.decode(str)
			Base64.decode64(str.tr('-_','+/'))
		end
	end

end