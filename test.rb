require 'geminiclient'
gemcli = Gemini::Client.new "geminiprotocol.net", 1965, "/Users/mouse/.gemini/tofudb.yml"
puts gemcli.get("/")
puts gemcli.shutdown 
