module Gemini
  class Client
    attr_accessor :connection, :Logger, :socket 
    def grab_gemsite(uri, path, port, method)
        puts "grabgem"
        puts uri.chomp('/')
        @ssl_context = OpenSSL::SSL::SSLContext.new
        @tofu_db = TofuDB.new "~/.gemini/tofudb.yml"
        @connection = Connection.new(@ssl_context, @tofu_db, true, uri, port)
        
        #ssl_context, tofu_db, uri, port
        status = @connection.status
        
        if status
          path = uri+'/'+path
          @socket = @connection.socket 
          return self._grab(path)
        else
          return {"data": ["connection failed"]}
        end
    end
    
    
    def _grab(fulluri)
        content = {}
        content[:header], content[:data] = self.send_request("#{fulluri}")
    end

    def send_input(site_path, input_data)
      ready_input = URI.encode_www_form_component(input_data).gsub('+','%20')
      return self.send_request site_path + '?' + ready_input
    end
    
    def send_request(uri)
      ## check ssl contexts, for sockets and urls
      @socket.connect()
      puts "send request"
      puts uri
      @socket.puts "gemini://#{uri}/\r\n"
      data = @socket.readlines
      header = data.slice!(0)
      content = data
      return header, content
    end
  end
end