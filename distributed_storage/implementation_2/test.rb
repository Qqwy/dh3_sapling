class DigestWrapper
	def self.digest(input)
		Digest.hexencode Digest::SHA2.digest(input)
	end
end


$hash_class = DigestWrapper


$dht = LocalHashTable.new($hash_class)

$key1 = $hash_class.digest('topsecret')
$val1 = {
	d: 'topsecret',
	r: nil,
	l: $hash_class.digest('topsecret'),
	s: 'todo'
	}


$val2 = {
	d: 'another value',
	r: $val1[:l],
	l: $hash_class.digest('another value'),
	s: 'todo'
	}


$ssd = SideStepDirection.new($hash_class, $key1)
$saltd = SaltDirection.new($hash_class, $key1, 'testsalt')

$directions = [
	$ssd,
	$saltd
]

$dht.store($key1, $val1.to_json)
$dht.store($ssd.next_key, $val2.to_json)

$tt = TreeTraverser.new($hash_class, $dht, $directions)

$rn = $tt.build_tree($key1)

puts $rn.children.first.data

$new_node = $rn.new_child($hash_class, "This is a triumph")
$new_node2 = $rn.children.last.new_child($hash_class, "I'm making a note here: Huge success!")

$saltd.key = $key1
$tt.save_tree($rn.collection, $saltd)


$rn2 = $tt.build_tree($key1)