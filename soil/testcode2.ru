#\ -p 4502
require './soil.rb'



known_addresses = %w(http://127.0.0.1:4501/)

use Soil::NodeMiddleware, Pathname.new("./data_store/config/config2.yml"), known_addresses, path:"/"

run Proc.new { |env| 
	puts env
	env['soil_node'].iterative_store(Soil.digest_class.digest("testkey"), "testvalue")
	['200', {'Content-Type' => 'text/html'}, ['This is node 2']] 
}
