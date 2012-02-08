module SlidingSessions
  # Allows using :session_expires_after option for session cookies
  # NOTE it does not perform any checks on server-side, it just
  # sets the session cookie expiration time.
  # see http://wiki.rubyonrails.org/rails/pages/HowtoChangeSessionOptions
  # for a recipe to perform server-side expiration checks

  # Copyright (C) 2008, Paweł Stradomski
  # Permission is hereby granted, free of charge, to any person
  # obtaining a copy of this software and associated documentation
  # files (the "Software"), to deal in the Software without
  # restriction, including without limitation the rights to use,
  # copy, modify, merge, publish, distribute, sublicense, and/or sell
  # copies of the Software, and to permit persons to whom the
  # Software is furnished to do so, subject to the following
  # conditions:
  # 
  # The above copyright notice and this permission notice shall be
  # included in all copies or substantial portions of the Software.
  # 
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  # OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  # HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  # WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  # FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  # OTHER DEALINGS IN THE SOFTWARE.

  def self.included(base)
    base.class_eval do
      alias_method_chain :set_session_options, :sliding
    end
  end

  def set_session_options_with_sliding(request) #:nodoc:
    set_session_options_without_sliding(request)
    if request.session_options && request.session_options[:session_expires_after] then
      request.session_options = request.session_options.clone
      request.session_options[:session_expires] = Time.now + request.session_options[:session_expires_after]
      
      # cookie store only sends cookie if data changed. But we need  to send it with every request
      # to update the expiration time
      request.session[:sliding_session_expiration] = request.session_options[:session_expires].to_s
    end
    
    request.session_options
  end
end

ActionController::Base.send(:include, SlidingSessions)
