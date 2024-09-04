Gemini client gem for gemini network work in progress, used in other project gemtoop - http to gemini proxy

For more information about the gemini protocol
https://gemini.circumlunar.space

to test basic functionality:
'''
gem build ./geminiclient.gemspec
gem install ./geminiclient-0.0.0.gem
'''

simple test script:
'''
require 'geminiclient'
gemcli = Gemini::GeminiClient.new
x = gemcli.grab_gemsite('geminiprotocol.net', '/', 1965)
'''