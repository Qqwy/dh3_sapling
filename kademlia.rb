=begin

	We have the following classes:

	# KademliaNode 		=> The 'abstract' instance of Kademlia that has a data store. It can add things to this store and read things from it.
	# KademliaServer 	=> The 'practical' implementation of a server that can be connected to, built on EventMachine. It will ask it's internal KademliaNode for details.
	# KademliaClient 	=> A client that connects to external KademliaServers to obtain information from there.
	# KademliaContact 	=> An object storing contact details (and last connection time, etc) of an external KademliaServer.

=end

require './lib/kademlia'




=begin



$kn = KademliaNode.new('test', {})
$c1 = KademliaContact.new('a', '127.0.0.1', 8083)

def run_event_machine
	EventMachine.run do
		EventMachine.start_server '127.0.0.1', '8082', KademliaServer
		puts "eventmachine starting"

		#TODO: Periodic timers to republish etc.
	end
end

=end
