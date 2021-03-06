class Direction

	attr_accessor :key

	def initialize(hash_class, key)
		throw "Unsupported Hash Class (does not respond to `digest(string)` )" unless hash_class.respond_to?(:digest)
		@hash_class = hash_class
		@key = $hash_class.digest(key)
	end

	def hash(input)
		@hash_class.digest(input)
	end

	def next_key
		hash(@key)
	end

	def key=(key)
		@key = $hash_class.digest(key)
	end

	def iterate_keys(amount=nil)
		keys = []
		loop do
			unless amount.nil?
				amount -= 1
				if amount < 0
					break
				end
			end
			if block_given?
				yield self.next_key
			else
				keys << self.next_key
			end
		end
		keys
	end


end


class SideStepDirection < Direction



	def next_key
		@key = hash(@key)
	end
end

class SaltDirection < Direction
	
	attr_accessor :salt
	def initialize(hash_class, start_key, salt)
		super(hash_class, start_key)
		@salt = salt.to_s
	end

	def next_key
		@key = hash(@key + @salt)
	end
end


#Is this useful for now?
class NonceDirection < Direction
	
	attr_accessor :secret, :nonce
	def initialize(hash_class, secret, nonce)
		super(hash_class, start_key)
		@secret = secret.to_s
		@nonce = nonce.to_i
	end

	def next_key
		@key = hash(secret + nonce.to_s)
		@nonce += 1

		return @key
	end
end