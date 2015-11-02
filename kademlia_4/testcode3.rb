require './kademlia.rb'


$kc1 = KademliaContact.new("contact1", "127.0.0.1", "4501")
$kc2 = KademliaContact.new("contact2", "127.0.0.1", "4502")
$kc3 = KademliaContact.new("contact3", "127.0.0.1", "4503")


#$kn1 = KademliaNode.new("contact1", "127.0.0.1", "4501", "/", [$kc2, $kc3])
#$kn2 = KademliaNode.new("contact2", "127.0.0.1", "4502", "/", [$kc1])
$kn3 = KademliaNode.new("contact3", "127.0.0.1", "4503", "/", Pathname.new("./data_store/config/config3.yml"), [$kc1, $kc2])



#$ks1 = $kn1.server# = KademliaServer.new($kn1, "4501")
#$ks2 = $kn2.server# = KademliaServer.new($kn2, "4502")
$ks3 = $kn3.server# = KademliaServer.new($kn3, "4503")



#$kn2.iterative_store($digest_class.digest("testkey"), "testvalue")