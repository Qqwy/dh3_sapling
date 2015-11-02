#require 'xmlrpc/server'
require 'rack/rpc'


#TODO: How to init as Rack RPC server? Config.ru -ish?
class KademliaServer < Rack::RPC::Server
	attr_accessor :node, :port, :s
	def initialize(node, port)
		@node = node
		node.server = self
		@port = port
		#@s = XMLRPC::Server.new(@port)



	end

		def kademlia_ping #@s.add_handler('kademlia.ping') do |contactor_info|
			@node.add_or_update_contact contactor_info
			@node.handle_ping(KademliaContact.from_hash(contactor_info)).to_hash
		end
		
		def kademlia_store #@s.add_handler('kademlia.store') do |contactor_info, key, value|
			@node.add_or_update_contact contactor_info
			@node.handle_store(key, value)
		end
		
		def kademlia_find_node #@s.add_handler('kademlia.find_node') do |contactor_info, key_hash| 
			@node.add_or_update_contact contactor_info
			@node.handle_find_node(key_hash)
		end
		
		def kademlia_find_value #@s.add_handler('kademlia.find_value') do |contactor_info, key_hash| 
			@node.add_or_update_contact contactor_info
			@node.handle_find_value(key_hash)
		end

		rpc 'kademlia.ping' => :kademlia_ping
		rpc 'kademlia.store' => :kademlia_store
		rpc 'kademlia.find_node' => :kademlia_find_node
		rpc 'kademlia.find_value' => :kademlia_find_value
		
		# @s.set_default_handler do |name, *args|
		# 	raise XMLRPC::FaultException.new(-99, "Method #{name} missing,  or wrong number of parameters!")
 	# 	end

 	# 	@event_thread = Thread.new do
		# 	@s.serve #Start server on separate thread.
		# end

	#end

	def stop
		Thread.kill(@event_thread)
	end
end



#ks = KademliaServer.new({},8080)



=begin
require 'eventmachine'

class KademliaServer < EventMachine::Connection
	#Called by EventMachine when the server socket is triggered by something.
	def post_init
		puts "Someone connected"
	end

	def receive_data(data)
		puts data

		case data.chomp
			when 'find' then send_data "finding something for you"
			when 'store' then send_data "storing something for you"
			when 'find_node' then send_data "Finding node for you"
			when 'find_value' then send_data "Finding value or closest node for you"
			when 'ping' then send_data 'pong'
			else send_data 'unknown command'
		end
		send_data "\n"
		send_data $kn.inspect
		send_data "\n"
		close_connection_after_writing
	end

	def unbind
		puts "connection closed"
	end
end


class KademliaStubServer

	attr_accessor :node
	def initialize(node)
		@node = node
	end

	def receive_data(raw_data)
		require 'json'
		data = JSON.parse(raw_data, symbolize_names: true)

		return {success:false} unless data[:command_name] && data[:parameters]

		@node.method(data[:command_name].to_sym).call(*data[:parameters])


	end
end
=end
