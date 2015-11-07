require 'uri'
require 'base64'

module Sapling
	class Contact

		attr_reader :node_id, :address, :public_key, :signature, :bcrypt_salt, :last_contact_time, :times_connected, :calls_me, :can_be_called

		def initialize(node_id, address, public_key='', signature='', bcrypt_salt='', contact_time: Time.now)
			@node_id = node_id
			@address = address
			@public_key = public_key
			@signature = signature
			@bcrypt_salt = bcrypt_salt
			@last_contact_time = contact_time #used to sort contacts and see which ones are still functioning.
			@times_connected = 0
			@calls_me = false
			@can_be_called = false
		end


		def self.valid_node_id?(address, public_key, signature, bcrypt_salt, node_id)
			require 'ecdsa'
			require 'bcrypt'
			group = ECDSA::Group::Secp256k1
			public_key_point = ECDSA::Format::PointOctetString.decode(public_key, group)
			digest = Sapling.digest_class.digest(address)
			signature_point = ECDSA::Format::SignatureDerString.decode(signature)


			return false if BCrypt::Engine.autodetect_cost(bcrypt_salt) < Sapling.bcrypt_salt_strengh

			test_node_id = Sapling.digest_class.digest(BCrypt::Engine.hash_secret(signature, bcrypt_salt))

			ECDSA.valid_signature?(public_key_point, digest, signature_point) && node_id == test_node_id
		end


		def client
			begin 
				uri = URI(@address)
				@client ||= Sapling::Client.new(uri.host, uri.port, path: uri.path.empty? ? "/" : uri.path) #Only initialize once. Re-use while Contact exists and program keeps running.
				yield @client 

				#This line is only executed if the connection was successfull
				@last_contact_time = Time.now
				@times_connected += 1
				@can_be_called = true

			rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, XMLRPC::FaultException, IOError => e
	       		$logger.warn "Connecting to `#{@address}` threw the following error: #{e}"

	       		self.can_be_called = false

	       		raise Sapling::ClientConnectionError
	   		end
	   		return true
		end

		def update_contact_time!
			@last_contact_time = Time.now
		end

		def called_me!
			@calls_me = true
		end

		def name
			"(#{self.node_id}<->#{self.address})"
		end

		def to_hash

			return {
				"node_id" => @node_id,
				"address" => @address,
				"public_key" => UrlsafePaddinglessBase64.encode(@public_key),
				"signature" => UrlsafePaddinglessBase64.encode(@signature),
				"bcrypt_salt" => UrlsafePaddinglessBase64.encode(@bcrypt_salt)
			}
		end

		def to_json
			self.to_hash.to_json
		end

		def self.from_hash(hash)
			Sapling::Contact.new(
					hash["node_id"],
					hash["address"],
					UrlsafePaddinglessBase64.decode(hash["public_key"]),
					UrlsafePaddinglessBase64.decode(hash["signature"]),
					UrlsafePaddinglessBase64.decode(hash["bcrypt_salt"]),
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
end