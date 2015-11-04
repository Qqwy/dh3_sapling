#\ -p 4502
require './sapling.rb'



known_addresses = %w(http://127.0.0.1:4501/)

use Sapling::NodeMiddleware, Pathname.new("./data_store/config/config2.yml"), known_addresses, path:"/"

run Proc.new { |env| 
	puts env
	env['sapling_node'].iterative_store($digest_class.digest("testkey"), "testvalue")
	['200', {'Content-Type' => 'text/html'}, ['This is node 2']] 
}
