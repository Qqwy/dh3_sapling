module Soil

	class BucketNotFoundError < StandardError; end
	class ClientConnectionError < StandardError; end
	class CorruptedConfigError < StandardError; end
	class NoPrivateKeyInConfigError < StandardError; end
	class NoAddressInConfigError < StandardError; end

end