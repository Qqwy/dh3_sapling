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