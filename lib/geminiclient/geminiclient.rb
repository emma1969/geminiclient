
#hash of ssl contexts
#no cert issuer check setting/tofu db always
#redirects
#sub request
#input queries

module Gemini
  class GeminiClient
    attr_accessor :tofu_db, :document, :ssl_context, :socket, :cert, :ca_file_path, :use_tofu
    
    def initialize(tofu_path='/root/.gemini/tofudb.yml', use_tofu=true)
      @ssl_context = OpenSSL::SSL::SSLContext.new
      @ssl_context.ca_file = "/Users/david/Documents/Certificates.pem"
      @use_tofu = use_tofu
      if use_tofu
        @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @socket = nil
      @cert = nil
      @tofu_db = Gemini::TofuDB.new tofu_path
      @use_tofu
    end
    
    
    def generate_client_root_ca
      root_key = OpenSSL::PKey::RSA.new 2048
      root_ca = OpenSSL::X509::Certificate.new
      root_ca.version = 2
      root_ca.serial = 1
      root_ca.subject = OpenSSL::X509::Name.parse "/DC=#{@cdc[0]}/DC=#{@cdc[1]}/CN=#{@cn}"
      root_ca.issuer = root_ca.subject
      root_ca.not_before = Time.now
      root_ca.not_after = root_ca.not_before + @ca_length
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = root_ca
      ef.issuer_certificate = root_ca
      root_ca.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
      root_ca.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
      root_ca.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
      root_ca.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
      root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)
      @root_ca = root_ca
      return true
    end
    
    def generate_client_key( dc, cn)
      key = OpenSSL::PKey::RSA.new 2048
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 2
      cert.subject = OpenSSL::X509::Name.parse "/DC=#{dc[0]}/DC=#{dc[1]}/CN=Ruby certificate"
      cert.issuer = root_ca.subject # root CA is the issuer
      cert.public_key = key.public_key
      cert.not_before = Time.now
      cert.not_after = cert.not_before + 1 * 365 * 24 * 60 * 60 # 1 years validity
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = root_ca
      cert.add_extension(ef.create_extension("keyUsage","digitalSignature", true))
      cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
      cert.sign(root_key, OpenSSL::Digest::SHA256.new)
      return cert
    end
    
    def add_client_key(socket,cert)
      
    end
    
    def send_input(site_path, input_data)
      ready_input = URI.encode_www_form_component(input_data).gsub('+','%20')
      return self.send_request site_path + '?' + ready_input
    end
    
    def establish_connection(uri, port)
      tcp_socket = TCPSocket.new(uri, port)
      #@socket = OpenSSL::SSL::SSLSocket.new(tcp_socket,@ssl_context)
      #the ssl context is causing an issue
      @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket)
      @socket.connect
      cert = @socket.peer_cert
      if use_tofu
        if @tofu_db.check_cert(uri,cert, @socket)
          @cert = @socket.peer_cert
          return true
        else
          puts 'SSL Error'
          return false
        end
      end
      return true
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
    
    def grab_gemsite(uri, path, port)
      puts "grabgem"
      puts uri.chomp('/')
      status = self.establish_connection( uri.chomp('/'), port )
      if status
        path = uri+'/'+path
        puts path
        return self._grab(path)
      else
        return {"data": ["connection failed"]}
      end
    end
    
    
    def _grab(fulluri)
      content = {}
      puts fulluri
      puts "fulluri"
      puts fulluri
      content[:header], content[:data] = self.send_request("#{fulluri}")
      begin 
        check = content[:header].split(' ')
        status = check[0].to_i
        data = check[1].chomp
      rescue
        status = 0
      end
      case status
      when 20..29
        return content
      when 30..31
        data.gsub!(/'/,"")
        puts "30..31"
        puts data
        return self._grab(data)
      when 50..51
        data.sub!("gemini://","").gsub!(/\/+/,"/").gsub!(/'/,"")
        puts "50..51"
        puts data
        return self._grab(data)
      else
        content[:data] = ["ERROR"]
      end
      return content
    end
    
    
  end
end
