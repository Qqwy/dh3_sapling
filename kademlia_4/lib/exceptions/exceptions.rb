module Exceptions

	class BucketNotFoundError < StandardError; end
	class KademliaClientConnectionError < StandardError; end
	class KademliaCorruptedConfigError < StandardError; end
	class KademliaNoPrivateKeyInConfigError < StandardError; end
	class KademliaNoAddressInConfigError < StandardError; end

end