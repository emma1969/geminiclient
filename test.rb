require 'geminiclient'
gemcli = Gemini::Client.new
puts gemcli.grab_gemsite("geminiprotocol.net", "/", 1965, nil)
