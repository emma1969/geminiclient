module Gemini
    class Connection
      attr_accessor :tofu_db, :document, :socket, :cert, :ssl_context, :status
      
      def initialize(ssl_context, tofu_db, use_tofu, uri, port)
        @ssl_context = ssl_context
        @tofu_db = tofu_db
        tcp_socket = TCPSocket.new(uri, port)
        @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, self.ssl_context)
        @socket.connect
        cert = self.socket.peer_cert
        if use_tofu
          if @tofu_db.check_cert(uri,cert, self.socket)
            @cert = self.socket.peer_cert
            @status = true
          else
            puts 'SSL Error'
            @status = false
          end
        end
      end

      

     
    end
end