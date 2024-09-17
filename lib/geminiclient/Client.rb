module Gemini
  class Client
    attr_accessor :connection, :Logger, :socket 
    
    def initialize(uri, port, tofu_path="~/.gemini/tofudb.yml")
      @ssl_context = OpenSSL::SSL::SSLContext.new
      @tofu_db = TofuDB.new tofu_path 
      @uri = uri 
      @port = port
      @connection = Connection.new(@ssl_context, @tofu_db, true, @uri, @port)
    end

    def get(path) 
        if @connection.status
          fulluri = "#{@uri}/#{path}"
          content = {}
          content[:header], content[:data] = @connection.send_request("#{fulluri}")
          return content
        else
          return {"data": ["connection failed"]}
        end
    end

    def put(site_path, input_data)
      ready_input = URI.encode_www_form_component(input_data).gsub('+','%20')
      return @connection.send_request site_path + '?' + ready_input
    end

    
  end
end