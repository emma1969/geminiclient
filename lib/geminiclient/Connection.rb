module Gemini
    class Connection
      attr_accessor :tofu_db, :document, :socket, :cert, :ssl_context
      
      def initialize(ssl_context, tofu_db, uri, port)
        self.ssl_context = ssl_context
        self.tofu_db = tofu_db
        tcp_socket = TCPSocket.new(uri, port)
        self.socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, self.ssl_context)
        self.socket.connect
        cert = self.socket.peer_cert
        if use_tofu
          if self.tofu_db.check_cert(uri,cert, self.socket)
            self.cert = self.socket.peer_cert
            return true
          else
            puts 'SSL Error'
            return false
          end
        end
        return true
      end
      
      def send_input(site_path, input_data)
        ready_input = URI.encode_www_form_component(input_data).gsub('+','%20')
        return self.send_request site_path + '?' + ready_input
      end
      
      def send_request(uri)
        ## check ssl contexts, for sockets and urls
        self.socket.connect()
        puts "send request"
        puts uri
        self.socket.puts "gemini://#{uri}/\r\n"
        data = self.socket.readlines
        header = data.slice!(0)
        content = data
        return header, content
      end
    end
end