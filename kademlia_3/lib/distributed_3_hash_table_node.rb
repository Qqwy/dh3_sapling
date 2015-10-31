class Distributed3HashTableNode
	def initialize(url, private_key, bootstrap_contacts=[])

		@url = url
		@node_id ="test"	#identifier of this node. TODO: Calculate using ECDSA
		@table 				# TODO: Move over to actual file storage.	
		@timestamps			# TODO: Move over to actual file storage.
		@buckets = []
		bootstrap_contacts.each do |contact|
			add_contact(contact)
		end
	end



	#calculates the distance between two hashes: This can both be used between two nodes, a node and a to-be-stored-or-read value or two values.
	def calc_distance(hasha, hashb)
		return hash_as_num(hasha) ^ hash_as_num(hashb) 
	end

	#Changes a hash in string representation to a Bignum.
	def hash_as_num(hexencoded_hash)
		[str].pack('H*')
	end


	def add_contact(contact)

	end

	def to_contact
		return Distributed3Contact.new(self.url, self.node_id)
	end

	def ping(contanct)

	end

	def handle_ping
		
	end


end