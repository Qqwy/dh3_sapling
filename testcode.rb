kn1 = KademliaNode.new("contact1", [KademliaContact.new("contact2", "127.0.0.1", "3002")])

kn2 = KademliaNode.new("contact2", [KademliaContact.new("contact2", "127.0.0.1", "3001")])

ks1 = KademliaServer.new(kn1, "3001")
ks2 = KademliaServer.new(kn2, "3002")