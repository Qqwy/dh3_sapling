#\ -p 4501
require './soil.rb'


known_addresses = %w(http://127.0.0.1:4502/)


use Soil::NodeMiddleware, Pathname.new("./data_store/config/config1.yml"), known_addresses, path:"/"

run Proc.new { |env| ['200', {'Content-Type' => 'text/html'}, ['This is node 1']] }
