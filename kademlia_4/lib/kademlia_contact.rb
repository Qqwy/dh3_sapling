#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

class KademliaContact

	attr_reader  :identifier, :node_id, :ip, :port, :path,:last_contact_time, :times_connected

	def initialize(identifier, address, port, path:"/", contact_time: Time.now())
		@identifier = identifier.to_s
		@node_id = $digest_class.digest @identifier
		@address = address
		@port = port
		@path = path || "/"
		@last_contact_time = contact_time #used to sort contacts and see which ones are still functioning.
		@times_connected = 0
	end

	def client
		begin 
			@client ||= KademliaClient.new(@address, @port, path: @path) #Only initialize once. Re-use while Contact exists and program keeps running.
			yield @client 

			#This line is only executed if the connection was successfull
			@last_contact_time = Time.now
			@times_connected += 1

		rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
       		$logger.warn "Connecting to `#{@address}:#{@port} -> #{@path}` threw the following error: #{e}"
       		raise Exceptions::KademliaClientConnectionError
   		end
   		return true
	end

	def to_hash
		return {
			"identifier" => @identifier,
			"address" => @address,
			"port" => @port,
			"path" => @path
		}
	end

	def to_json
		self.to_hash.to_json
	end

	def self.from_hash(hash)
		$logger.debug hash
		KademliaContact.new(
				hash["identifier"],
				hash["address"],
				hash["port"],
				path: hash["path"]
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