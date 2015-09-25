#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

class KademliaValue
	attr_accessor :key, :value, :expires
	def initialize(value, expires=Time.now()+@@tExpire)
		@key = $digest_class.digest value
		@value = value
		@expires = expires
	end
end
