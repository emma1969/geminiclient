require 'geminiclient'
gemcli = Gemini::Client.new "geminiprotocol.net", 1965
puts gemcli.get("/")
