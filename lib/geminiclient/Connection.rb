module Gemini
    class Connection
      attr_accessor :tofu_db, :document, :socket, :cert, :ssl_context, :status, :uri
      
      def initialize(tofu_path, use_tofu, uri, port)
        @ssl_context = OpenSSL::SSL::SSLContext.new
        tcp_socket = TCPSocket.new(uri, port)
        @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, @ssl_context)
        @socket.connect
        @uri = uri
        cert = self.socket.peer_cert
        if use_tofu
          @tofu_db = TofuDB.new tofu_path 
          if @tofu_db.check_cert(uri,cert, self.socket)
            @cert = self.socket.peer_cert
            @status = true
          else
            puts 'SSL Error'
            @status = false
          end
        end
      end

      def send_request(path)
        fulluri = "#{@uri}/#{path}"
        @socket.puts "gemini://#{fulluri}/\r\n"
        data = @socket.readlines
        header = data.slice!(0)
        content = data
        return header, content
      end

      def close
        @socket.close
        @tofu_db.write
      end
    end

    
end