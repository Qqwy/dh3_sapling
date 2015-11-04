require './kademlia'

ports = (1..100).to_a.map do |x| 6000+x end
puts ports

$contacts = ports.map do |port|
	SaplingContact.new(port, '127.0.0.1',port)
end

$contacts.each do |contact|
	Thread.new do 
		kn = SaplingNode.new(contact.identifier, $contacts - [contact])
		ks = SaplingServer.new(kn,contact.port)
	end
end

$kn = SaplingNode.new($contacts.first.identifier, $contacts - [$contacts.first])