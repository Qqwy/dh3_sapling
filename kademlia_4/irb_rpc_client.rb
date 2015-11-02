require 'xmlrpc/client'
require 'digest/sha2'

def digest(key)
	Digest.hexencode(Digest::SHA2.digest(key))
end

$c = XMLRPC::Client.new('127.0.0.1','/', "4501")

