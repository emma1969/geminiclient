require 'socket'
require 'openssl'
require 'yaml'
%w[ geminiclient tofudb ].each do |file|
  require "geminiclient/#{file}"
end
