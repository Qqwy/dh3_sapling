require './kademlia.rb'


# $kc1 = KademliaContact.new("contact1", "http://127.0.0.1:4501")
# $kc2 = KademliaContact.new("contact2", "http://127.0.0.1:4502")
# $kc3 = KademliaContact.new("contact3", "http://127.0.0.1:4503")

known_addresses = %w(http://127.0.0.1:4502)


$kn = KademliaNode.new(Pathname.new("./data_store/config/config1.yml"), known_addresses)
#$kn2 = KademliaNode.new("contact2", "127.0.0.1", "4502", "/", [$kc1, $kc3])
#$kn3 = KademliaNode.new("contact3", "127.0.0.1", "4503", "/", [$kc1, $kc2])



$ks = $kn.server# = KademliaServer.new($kn1, "4501")
#$ks2 = $kn2.server# = KademliaServer.new($kn2, "4502")
#$ks3 = $kn3.server# = KademliaServer.new($kn3, "4503")



#$kn1.iterative_store($digest_class.digest("testkey"), "testvalue")