=begin

	We have the following classes:

	# SoilNode 		=> The 'abstract' instance of Soil that has a data store. It can add things to this store and read things from it.
	# SoilServer 	=> The 'practical' implementation of a server that can be connected to, built on EventMachine. It will ask it's internal SoilNode for details.
	# SoilClient 	=> A client that connects to external SoilServers to obtain information from there.
	# SoilContact 	=> An object storing contact details (and last connection time, etc) of an external SoilServer.

=end

require './lib/soil'




=begin



$kn = SoilNode.new('test', {})
$c1 = SoilContact.new('a', '127.0.0.1', 8083)

def run_event_machine
	EventMachine.run do
		EventMachine.start_server '127.0.0.1', '8082', SoilServer
		puts "eventmachine starting"

		#TODO: Periodic timers to republish etc.
	end
end

=end
