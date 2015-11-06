=begin

	We have the following classes:

	# SaplingNode 		=> The 'abstract' instance of Sapling that has a data store. It can add things to this store and read things from it.
	# SaplingServer 	=> The 'practical' implementation of a server that can be connected to, built on EventMachine. It will ask it's internal SaplingNode for details.
	# SaplingClient 	=> A client that connects to external SaplingServers to obtain information from there.
	# SaplingContact 	=> An object storing contact details (and last connection time, etc) of an external SaplingServer.

=end

module Sapling
	require './lib/exceptions/exceptions.rb'

	require './lib/digest'
	require './lib/node'
	# require './lib/kademlia_server'
	require './lib/hash_table'
	require './lib/bucket_list'
	require './lib/bucket'
	require './lib/contact'
	require './lib/client'

	require './lib/node_middleware'



	require './lib/keccak_digest'
	@digest_class = KeccakDigest
	@bcrypt_salt_strengh = 15
	class << self
		attr_accessor :digest_class, :bcrypt_salt_strengh

	end



	require 'logger'

	$logger = Logger.new(STDOUT)
	$logger.level = Logger::DEBUG



	

end