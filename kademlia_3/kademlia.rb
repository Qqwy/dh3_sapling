
require './lib/distributed_3_hash_table_node.rb'

# This implementation works like Kademlia, with the following differences:
# just like in the BitTorrent `Mainline DHT`, there at first only is one bucket that is split once it becomes full.
# Attempting to STORE a different(!) value under the same key results in the value being stored in one key further in DH3 Direction A `hash(old_key)`


