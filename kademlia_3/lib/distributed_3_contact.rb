class Distributed3Contact
	

	#TODO: Public Key, Signature.

	attr_accessor :url, :node_id
	def initialize(url, node_id)
		@url, @node_id = url, node_id
	end
end