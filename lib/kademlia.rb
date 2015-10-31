=begin

	We have the following classes:

	# KademliaNode 		=> The 'abstract' instance of Kademlia that has a data store. It can add things to this store and read things from it.
	# KademliaServer 	=> The 'practical' implementation of a server that can be connected to, built on EventMachine. It will ask it's internal KademliaNode for details.
	# KademliaClient 	=> A client that connects to external KademliaServers to obtain information from there.
	# KademliaContact 	=> An object storing contact details (and last connection time, etc) of an external KademliaServer.

=end

class StubDigest
	def self.digest(hash)
		return hash.to_s
	end
end

class SHA256Digest
	require 'digest'
	require 'base64'

	def self.digest(hash)
		return Digest.hexencode Digest::SHA2.digest(hash)
		#return Base64.urlsafe_encode64(Digest::SHA256.digest(hash.to_s))
		#.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
	end

	def self.to_num(hash_as_str)
		hash_as_str.to_i(16)
	end
end

$digest_class = SHA256Digest #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method
#StubDigest



require './lib/kademlia_node'
require './lib/kademlia_server'
require './lib/kademlia_value'
require './lib/kademlia_contact'
require './lib/kademlia_client'







=begin


$c1 = KademliaContact.new('a', '127.0.0.1', 8083)
$kn = KademliaNode.new('test', [$c1])

def run_event_machine
	EventMachine.run do
		EventMachine.start_server '127.0.0.1', '8082', KademliaServer
		puts "eventmachine starting"

		#TODO: Periodic timers to republish etc.
	end
end

=end
