module Gemini
  class Client
    attr_accessor :connection, :Logger, :socket 
    
    def initialize(uri, port, tofu_path="~/.gemini/tofudb.yml", use_tofu=true)
      @connection = Connection.new(tofu_path, use_tofu, uri, port)
    end

    def get(path) 
        if @connection.status
          content = {}
          content[:header], content[:data] = @connection.send_request("#{path}")
        else
          content = {"data": ["connection failed"]}
        end
        return content
    end

    def put(site_path, input_data)
      ready_input = URI.encode_www_form_component(input_data).gsub('+','%20')
      return @connection.send_request site_path + '?' + ready_input
    end

    def shutdown
      @connection.close
      return true 
    end

    
  end
end