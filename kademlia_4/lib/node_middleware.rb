module Sapling
	class NodeMiddleware
		attr_reader :app

		attr_reader :options

		def initialize(app, kademlia_configfile_path, known_addresses, options={})
			@app = app
			@options = options.dup

			@kademlia_configfile_path = kademlia_configfile_path
			@known_addresses = known_addresses

			@node = Sapling::Node.new(Pathname.new(kademlia_configfile_path), known_addresses)
			@server = Rack::RPC::Endpoint.new @app, @node, path: "/"
		end

		def call(env)
			env['sapling_node'] = @node #Add handle to node to the env stack, so Rack apps down the line can access it.
			@server.call(env)
		end
	end
end