#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

require 'uri'
require 'base64'

class KademliaContact

	attr_reader :node_id, :address, :public_key, :signature, :last_contact_time, :times_connected

	def initialize(node_id, address, public_key='', signature='', contact_time: Time.now)
		@node_id = node_id
		@address = address
		@public_key = public_key
		@signature = signature
		@last_contact_time = contact_time #used to sort contacts and see which ones are still functioning.
		@times_connected = 0
	end

	def client
		begin 
			uri = URI(@address)
			@client ||= KademliaClient.new(uri.host, uri.port, path: uri.path.empty? ? "/" : uri.path) #Only initialize once. Re-use while Contact exists and program keeps running.
			yield @client 

			#This line is only executed if the connection was successfull
			@last_contact_time = Time.now
			@times_connected += 1

		rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, XMLRPC::FaultException => e
       		$logger.warn "Connecting to `#{@address}` threw the following error: #{e}"
       		raise Exceptions::KademliaClientConnectionError
   		end
   		return true
	end

	def update_contact_time!
		@last_contact_time = Time.now
	end

	def name
		"(#{self.node_id}<->#{self.address})"
	end

	def to_hash

		return {
			"node_id" => @node_id,
			"address" => @address,
			"public_key" => Base64.encode64(@public_key),
			"signature" => Base64.encode64(@signature)
		}
	end

	def to_json
		self.to_hash.to_json
	end

	def self.from_hash(hash)
		$logger.debug hash
		KademliaContact.new(
				hash["node_id"],
				hash["address"],
				Base64.decode64(hash["public_key"]),
				Base64.decode64(hash["signature"])
			)
	end

	def self.from_json(json_string)
		self.from_hash(JSON.parse(json_string))
	end


	def ==(other)
		return false unless other.kind_of? (self.class)
		return true if self.hash == other.hash

		return self.to_hash == other.to_hash
	end


end