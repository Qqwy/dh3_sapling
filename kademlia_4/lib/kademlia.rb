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


class ModifiedBase64
	def self.encode(str)
		Base64.encode64(str).tr('+/','-_').gsub(/[\n=]/,'')
	end

	def self.decode(str)
		Base64.decode64(str.tr('-_','+/'))
	end
end


#TODO: Find better way to do this. For instance, using Base64? (How to go from Base64-string to int?)
class SHA256Digest
	require 'digest'
	require 'base64'

	def self.digest(hash)
		return Digest::SHA2.hexdigest(hash)
	end

	def self.to_num(hash_as_str)
		hash_as_str.to_i(16)
	end

	# Also known as `B` in the Kademlia specification. The number of unique keys that can be constructed using this hashing function.
	def self.hash_size
		2**256
	end
end

$digest_class = SHA256Digest #Used for internal digest creation. Change to use a different kind of hashing type. Everything goes, as long as it supports the .digest(string) method
#StubDigest


require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG



require './lib/exceptions/exceptions.rb'

require './lib/kademlia_node'
# require './lib/kademlia_server'
require './lib/hash_table'
require './lib/kademlia_bucket_list'
require './lib/kademlia_bucket'
require './lib/kademlia_contact'
require './lib/kademlia_client'

require './lib/kademlia_node_middleware'






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
