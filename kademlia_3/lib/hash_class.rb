#Can be replaced by another hash-creating library.
#Important is that the result is always hexencoded, or otherwise Distributed3HashTableNode#hash_as_num will fail.
class HashClass

	def self.digest(key)
		return Digest.hexencode Digest::SHA2.digest(key)
	end
end