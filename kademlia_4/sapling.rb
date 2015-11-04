=begin

	We have the following classes:

	# SaplingNode 		=> The 'abstract' instance of Sapling that has a data store. It can add things to this store and read things from it.
	# SaplingServer 	=> The 'practical' implementation of a server that can be connected to, built on EventMachine. It will ask it's internal SaplingNode for details.
	# SaplingClient 	=> A client that connects to external SaplingServers to obtain information from there.
	# SaplingContact 	=> An object storing contact details (and last connection time, etc) of an external SaplingServer.

=end

require './lib/sapling'




=begin



$kn = SaplingNode.new('test', {})
$c1 = SaplingContact.new('a', '127.0.0.1', 8083)

def run_event_machine
	EventMachine.run do
		EventMachine.start_server '127.0.0.1', '8082', SaplingServer
		puts "eventmachine starting"

		#TODO: Periodic timers to republish etc.
	end
end

=end
