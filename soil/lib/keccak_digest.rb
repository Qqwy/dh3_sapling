#The standard Digest implementation
#Uses Keccak (SHA3) to generate hashes.
#Hashes are stored in Base64-format, with the following changes:
# '+' and '/' are replaced by '-' and '_' respectively (known as `urlsafe Base64`)
# As concatenation of hashes is not necessary, any padding `=` are stripped.
require 'digest'
require 'digest/sha3'
require 'base64'

	class KeccakDigest < Soil::Digest

		def self.hash_length
			512
		end

		#Hashes a key, returning a SHA3-hash, in urlsafe paddingless Base64 format.
		def self.digest(key)
			return Soil::UrlsafePaddinglessBase64.encode(Digest::SHA3.digest(key, self.hash_length))
		end

		#Adds all consecutive chars together to find the numerical value of the hash.
		#This numerical value is needed to do XOR calculations.
		def self.to_num(hash_as_str)
			Soil::UrlsafePaddinglessBase64.decode(hash_as_str).unpack('C*').inject(0) {|a,e| a<<=8;a+=e}
		end

		# Also known as `B` in the Kademlia specification. The number of unique keys that can be constructed using this hashing function.
		def self.hash_size
			2**self.hash_length
		end

	end

	
