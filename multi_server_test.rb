require './kademlia'

ports = (1..100).to_a.map do |x| 6000+x end
puts ports

$contacts = ports.map do |port|
	KademliaContact.new(port, '127.0.0.1',port)
end

$contacts.each do |contact|
	Thread.new do 
		kn = KademliaNode.new(contact.identifier, $contacts - [contact])
		ks = KademliaServer.new(kn,contact.port)
	end
end

$kn = KademliaNode.new($contacts.first.identifier, $contacts - [$contacts.first])