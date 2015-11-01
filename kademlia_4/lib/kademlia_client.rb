require 'xmlrpc/client'


class KademliaClient
	attr_accessor :address, :port, :path, :xmlrpc_client

	def initialize(address, port, path:"/")
		@address = address
		@port = port
		@path = path
		@xmlrpc_client = XMLRPC::Client.new(address, path, port)
	end

	def ping(contact_info)
		@xmlrpc_client.call('kademlia.ping', contact_info)
	end

	def store(key, value)
		@xmlrpc_client.call('kademlia.store',key, value)
	end

	def find_node(key_hash)
		@xmlrpc_client.call('kademlia.find_node', key_hash)
	end

	def find_value(key_hash)
		@xmlrpc_client.call('kademlia.find_value', key_hash)
	end
 

end