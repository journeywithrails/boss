

	

require 'cgi'
require 'cgi/session'
require 'base64'
require 'openssl'
require 'digest/sha1'
require 'benchmark'

class TamperedWithCookie < RuntimeError; end

class CookieStore
  def initialize(session, options = {})
    unless options['secret']
      raise ArgumentError, 'No secret yo'
    end

    @session, @secret = session, options['secret']

    @digest = options['digest'] || 'SHA1'
  end

  def generate_digest(data)
    key = @secret.respond_to?(:call) ? @secret.call(@session) : @secret
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new(@digest), key, data)
  end

  def marshal(session)
    data = Base64.encode64(Marshal.dump(session)).chop
    CGI.escape "#{data}--#{generate_digest(data)}"
  end

  def unmarshal(cookie)
    if cookie
      data, digest = CGI.unescape(cookie).split('--')
      unless digest == generate_digest(data)
        raise TamperedWithCookie
      end
      Marshal.load(Base64.decode64(data))
    end
  end
end

class EncryptedCookieStore < CookieStore
  def initialize(session, options = {})
    @cipher = options['cipher'] || 'blowfish'
    super
  end

  def marshal(session)
    c = OpenSSL::Cipher::Cipher.new(@cipher)
    c.encrypt @secret
    data = c.update Marshal.dump(session)
    data << c.final
    CGI.escape Base64.encode64(data)
  end

  def unmarshal(cookie)
    return unless cookie

    begin
      c = OpenSSL::Cipher::Cipher.new(@cipher)
      c.decrypt @secret
      data = c.update Base64.decode64(CGI.unescape(cookie))
      data << c.final
      Marshal.load data
    rescue
      raise TamperedWithCookie
    end
  end
end

[CookieStore, EncryptedCookieStore].each do |store_type|
  store = store_type.new nil, 'secret' => Digest::SHA1.hexdigest('foobar')

  3.times do
    puts Benchmark.measure {
      10000.times { store.unmarshal store.marshal('foobar') }
    }
  end
end



class CGI::Session::CookieStore
  
  def marshal(session)
    data = Base64.encode64(encrypt(Marshal.dump(session))).gsub("\n",'')
    CGI.escape "#{data}--#{generate_digest(data)}"
  end
  
  def unmarshal(cookie)
    if cookie
      data, digest = CGI.unescape(cookie).split('--')
      unless digest == generate_digest(data)
        delete
        raise TamperedWithCookie
      end
      Marshal.load(decrypt(Base64.decode64(data))) rescue nil
    end
  end
  
  def cipher_key
    @cipher_key ||= Digest::SHA2.digest(@secret.respond_to?(:call) ? @secret.call(@session) : @secret)
  end
  
  def cipher_iv
    @cipher_iv ||= Digest::SHA2.digest((@secret.respond_to?(:call) ? @secret.call(@session) : @secret).reverse)
  end
  
  def encrypt(cookie)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.encrypt
    cipher.key = cipher_key
    cipher.iv  = cipher_iv
    encrypted_cookie = cipher.update(cookie)
    encrypted_cookie << cipher.final
  end
  
  def decrypt(cookie)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.decrypt
    cipher.key = cipher_key
    cipher.iv  = cipher_iv
    decrypted_cookie = cipher.update(cookie)
    decrypted_cookie << cipher.final
  end
end