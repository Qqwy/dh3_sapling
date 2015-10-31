#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

class KademliaValue

	@@tExpire = 36000

	attr_accessor :key, :value, :expires
	def initialize(key, value, expires=Time.now()+@@tExpire)
		@key = key
		@value = value
		@expires = expires
	end
end
