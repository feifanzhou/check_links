require "http/server"

server = HTTP::Server.new(9999) do |context|
  if context.request.path == "/404"
    context.response.status_code = 404
    context.response.print("404")
  else
    filename = ".#{context.request.path}"
    context.response.content_type = "text/html"
    context.response.print(File.read(filename))
  end
end
p "Starting test server on port 9999"
server.listen