#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

class KademliaContact

	attr_accessor :identifier, :node_id, :ip, :port, :path, :last_contact_time

	def initialize(identifier, address, port, path:"/", contact_time: Time.now())
		@identifier = identifier
		@node_id = $digest_class.digest identifier
		@address = address
		@port = port
		@path = path
		@last_contact_time = contact_time #used to sort contacts and see which ones are still functioning.
	end

	def client
		return KademliaClient.new(@address, @port, path: @path)
	end

	def to_json
		return {
			identifier: @identifier,
			node_id: @node_id,
			address: @address,
			port: @port,
			path: @path#,
			#last_contact_time: @last_contact_time
		}
	end

	def self.from_hash(hash)
		puts hash
		#require 'json'
		#json = JSON.parse(raw_json, symbolize_names: true)
		KademliaContact.new(
				hash["identifier"],
				hash["address"],
				hash["port"],
				path: hash["path"]#,
				#json[:last_contact_time]
			)
	end

end