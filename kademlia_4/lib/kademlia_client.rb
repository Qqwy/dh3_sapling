require 'xmlrpc/client'
require 'json'

class KademliaClient
	attr_accessor :address, :port, :path, :xmlrpc_client

	def initialize(address, port, path:"/")
		@address = address
		@port = port
		@path = path
		@xmlrpc_client = XMLRPC::Client.new(
			address,#host
			path, 	#path
			port,	#port
			nil,	#proxy host
			nil,	#proxy port
			nil,	#username
			nil,	#password
			nil,	#use_ssl
			10		#timeout
			)
	end

	def ping(contact)
		KademliaContact.from_hash @xmlrpc_client.call('kademlia.ping', contact.to_hash)
	end

	def store(key, value)
		@xmlrpc_client.call('kademlia.store',key, value)
	end

	def find_node(key_hash)
		@xmlrpc_client.call('kademlia.find_node', key_hash)
	end

	def find_value(key_hash)
		result = @xmlrpc_client.call('kademlia.find_value', key_hash)
	end
 

end