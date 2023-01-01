module Gemini
  class CertManager 
    attr_accessor :Connection, :Logger
    def grab_gemsite(uri, path, port, method(:logger))
        puts "grabgem"
        puts uri.chomp('/')
        Connection = Connection.new(uri, port)
        status = self.establish_connection( uri.chomp('/'), port )
        if status
        path = uri+'/'+path
        return self._grab(path)
        else
        return {"data": ["connection failed"]}
        end
    end
    
    
    def _grab(fulluri)
        content = {}
        content[:header], content[:data] = Connection.send_request("#{fulluri}")
    end
  end
end