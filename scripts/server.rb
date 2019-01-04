require 'webrick'

mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
mime_types.store('wasm', 'application/wasm')

server = WEBrick::HTTPServer.new(
  :Port            => 8081,
  :DocumentRoot    => ".",
)


# The following command will provide a hook to shutdown the server (often done with Ctrl+C)
trap('INT') {server.shutdown}

# Start the server
server.start
