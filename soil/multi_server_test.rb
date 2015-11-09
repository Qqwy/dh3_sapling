require './kademlia'

ports = (1..100).to_a.map do |x| 6000+x end
puts ports

$contacts = ports.map do |port|
	SoilContact.new(port, '127.0.0.1', port)
end

$contacts.each do |contact|
	Thread.new do 
		kn = SoilNode.new(contact.identifier, $contacts - [contact])
		ks = SoilServer.new(kn,contact.port)
	end
end

$kn = SoilNode.new($contacts.first.identifier, $contacts - [$contacts.first])