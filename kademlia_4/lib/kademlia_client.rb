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

	def ping(contactor_info)
		@xmlrpc_client.call('n2n_ping', contactor_info.to_hash)
	end

	def store(contactor_info, key, value)
		@xmlrpc_client.call('n2n_store', contactor_info.to_hash, key, value)
	end

	def find_node(contactor_info, key_hash)
		@xmlrpc_client.call('n2n_find_node', contactor_info.to_hash, key_hash)
	end

	def find_value(contactor_info, key_hash)
		result = @xmlrpc_client.call('n2n_find_value', contactor_info.to_hash, key_hash)
	end
 

end