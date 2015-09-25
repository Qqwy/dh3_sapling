#require 'digest'
#$digest_class = Digest::SHA256 #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method

class KademliaContact

	attr_accessor :identifier, :node_id, :ip, :port, :path, :last_contact_time

	def initialize(identifier, address, port, path:"/", contact_time: Time.now())
		@identifier = identifier.to_s
		@node_id = $digest_class.digest @identifier
		@address = address
		@port = port
		@path = path
		@last_contact_time = contact_time #used to sort contacts and see which ones are still functioning.
	end

	def client
		begin 
			yield KademliaClient.new(@address, @port, path: @path)
		rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
       		puts "Connecting to `#{@address}:#{@port} -> #{@path}` threw the following error: #{e}"
   		end
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