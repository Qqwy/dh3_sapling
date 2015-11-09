=begin

	We have the following classes:

	# SoilNode 		=> The 'abstract' instance of Soil that has a data store. It can add things to this store and read things from it.
	# SoilServer 	=> The 'practical' implementation of a server that can be connected to, built on EventMachine. It will ask it's internal SoilNode for details.
	# SoilClient 	=> A client that connects to external SoilServers to obtain information from there.
	# SoilContact 	=> An object storing contact details (and last connection time, etc) of an external SoilServer.

=end

module Soil
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