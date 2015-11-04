class KademliaNodeMiddleware
	attr_reader :app

	attr_reader :options

	def initialize(app, kademlia_configfile_path, known_addresses, options={})
		@app = app
		@options = options.dup

		@kademlia_configfile_path = kademlia_configfile_path
		@known_addresses = known_addresses

		@node = KademliaNode.new(Pathname.new(kademlia_configfile_path), known_addresses)
		@server = Rack::RPC::Endpoint.new @app, @node, path: "/"
	end

	def call(env)
		env['kademlia_node'] = @node
		@server.call(env)
	end
end