#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

class KademliaContact

	attr_accessor :identifier, :node_id, :ip, :port, :last_contact_time

	def initialize(identifier, ip, port, contact_time: Time.now())
		@identifier = identifier
		@node_id = $digest_class.digest identifier
		@ip = ip
		@port = port
		@last_contact_time = contact_time #used to sort contacts and see which ones are still functioning.
	end

end