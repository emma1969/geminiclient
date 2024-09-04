require 'date'
module Gemini
  class TofuDB
    
    attr_accessor :DB, :path
    
    def initialize(path)
      if File.exist? path
        self.DB = YAML.load_file(path)
      else
        self.DB = {}
      end
      self.path = path
    end
    
    def check_tofu(uri, cert)
      now = DateTime.now.to_time
      expires = cert.not_after
      valid_on = cert.not_before
      if self.DB.key? uri and now < expires
        if self.DB[uri][:public_key] == cert.public_key.to_s and self.DB[uri][:expires] == expires
          return true
        else
          if self.DB[uri][:expires] < now and expires > self.DB[uri][:expires]
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
        puts ssl_socket.verify_result
        puts "Subject #{subjectbits['CN']}"
        puts "Issuer #{issuerbits['CN']}"
        indb = self.check_tofu(uri, cert)
        if indb
          success = true
          puts 'indb'
        else
          puts 'adding to db'
          self.add_tofu(uri, cert)
          success = true
        end
        if success
          status = 'accepted by tofudb'
        else
          status = 'rejected by tofudb'
        end
      end
      puts verify_res
      return success 
    end

    def update_tofu(uri, cert)
      self.DB[uri] = {
      :public_key => cert.public_key.to_s,
      :valid_on => cert.not_before,
      :expires => cert.not_after
      }
      return self.verify_function.call uri, cert
    end
  
    def add_tofu(uri, cert)
      now = DateTime.now.to_time
      expires = cert.not_after
      valid_on = cert.not_before
      self.DB[uri] = {
      :public_key => cert.public_key.to_s, 
      :valid_on => cert.not_before,
      :expires => cert.not_after
      }
      return "pee"
    end

    def verify_function(uri, cert, method)
      puts "verify function"
      puts cert.public_key.to_s
      puts cert.not_before
      puts cert.not_after
      return true
    end

    def remove_tofu(uri)
      self.DB.delete uri
    end

    def close
      File.open(self.path, 'w') do |yam|
        YAML.dump(self.DB,yam)
      end
    end

  end

end

