require './kademlia.rb'


$kc1 = KademliaContact.new("contact1", "127.0.0.1", "4001")
$kc2 = KademliaContact.new("contact2", "127.0.0.1", "4002")
$kc3 = KademliaContact.new("contact2", "127.0.0.1", "4003")


$kn1 = KademliaNode.new("contact1", [$kc2, $kc3])
$kn2 = KademliaNode.new("contact2", [$kc1, $kc3])
$kn3 = KademliaNode.new("contact3", [$kc1,$kc2])



$ks1 = KademliaServer.new($kn1, "4001")
$ks2 = KademliaServer.new($kn2, "4002")
$ks3 = KademliaServer.new($kn3, "4003")



$kn1.iterative_store($digest_class.digest("testkey"), "testvalue")