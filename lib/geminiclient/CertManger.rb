module Gemini
    class CertManager
      attr_accessor :tofu_db, :document, :ssl_context, :socket, :cert, :ca_file_path, :use_tofu
      
      def initialize(tofu_path='~/.gemini/tofudb.yml', use_tofu=true, ca_file="~/.config/Certs/Certificates.pem")
        self.ssl_context = OpenSSL::SSL::SSLContext.new
        self.ssl_context.ca_file = ca_file
        self.use_tofu = use_tofu
        if use_tofu
          self.ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        self.socket = nil
        self.cert = nil
      end

      def generate_client_root_ca
        root_key = OpenSSL::PKey::RSA.new 2048
        root_ca = OpenSSL::X509::Certificate.new
        root_ca.version = 2
        root_ca.serial = 1
        root_ca.subject = OpenSSL::X509::Name.parse "/DC=#{self.cdc[0]}/DC=#{self.cdc[1]}/CN=#{self.cn}"
        root_ca.issuer = root_ca.subject
        root_ca.not_before = Time.now
        root_ca.not_after = root_ca.not_before + self.ca_length
        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = root_ca
        ef.issuer_certificate = root_ca
        root_ca.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
        root_ca.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
        root_ca.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
        root_ca.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
        root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)
        self.root_ca = root_ca
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
    end
end