require 'date'
module Gemini
  class TofuDB
    
    attr_accessor :DB, :path
    
    def initialize(path)
      if File.exist? path
        @DB = YAML.load_file(path, permitted_classes: [Time, Symbol])
      else
        @DB = {}
      end
      @path = path
    end
    
    def check_tofu(uri, cert)
      now = DateTime.now.to_time
      expires = cert.not_after
      valid_on = cert.not_before
      if @DB.key? uri and now < expires
        if @DB[uri][:public_key] == cert.public_key.to_s and @DB[uri][:expires] == expires
          return true
        else
          if @DB[uri][:expires] < now and expires > @DB[uri][:expires]
            return self.update_tofu(uri, cert)
          else
            return false
          end
        end
      else
        return false
      end
    end

    def check_cert(uri, cert, ssl_socket)
      subjectbits = cert.subject.to_s.split('/').reject { |mstr| mstr.empty? }.map { |nstr| nstr.split('=') }.to_h
      issuerbits = cert.issuer.to_s.split('/').reject { |mstr| mstr.empty? }.map { |nstr| nstr.split('=') }.to_h
      verify_res = ssl_socket.verify_result
      success = false
      if (verify_res == 18 || verify_res == 19) || verify_res == 0
        indb = self.check_tofu(uri, cert)
        if indb
          success = true
        else
          self.add_tofu(uri, cert)
          success = true
        end
        if success
          status = 'accepted by tofudb'
        else
          status = 'rejected by tofudb'
        end
      end
      return success 
    end

    def update_tofu(uri, cert)
      @DB[uri] = {
      :public_key => cert.public_key.to_s,
      :valid_on => cert.not_before,
      :expires => cert.not_after
      }
      self.write
      return self.verify_function.call uri, cert
    end
  
    def add_tofu(uri, cert)
      now = DateTime.now.to_time
      expires = cert.not_after
      valid_on = cert.not_before
      @DB[uri] = {
      :public_key => cert.public_key.to_s, 
      :valid_on => cert.not_before,
      :expires => cert.not_after
      }
      self.write
    end

    def verify_function(uri, cert, method)
      puts "verify function"
      puts cert.public_key.to_s
      puts cert.not_before
      puts cert.not_after
      return true
    end

    def remove_tofu(uri)
      @DB.delete uri
      self.write 
    end

    def write
      File.open(@path, 'w') do |yam|
        YAML.dump(@DB,yam)
      end
    end

  end

end

