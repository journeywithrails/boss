module CASClient
  module Frameworks
    module Rails
      # This class mediates between the application and the CAS server. 
      # It implements the Rails filter method, used in controllers. 
      # It can also be used directly to perform authentication
      # 
      # === Configuration
      # A class method called +configure+ is used to configure the filter to
      # work with a particular CAS setup. It is designed to be called in an
      # environment file like so:
      # <tt>CASClient::Frameworks::Rails::Filter.configure{...}</tt>
      # 
      class Filter
        cattr_reader :config, :log, :client, :impl, :locale_callback, :user_prefill_callback
        
        # These are initialized when you call configure.
        @@config = nil
        @@client = nil
        @@log = nil
        @@impl = nil

        attr_accessor :do_redirect, :handle_gatewaying, :returning, :controller, :service_url
        
        class << self
          def filter(controller)
            instance = new(controller)
            instance.do_redirect = true
            instance.handle_gatewaying = true
            instance.returning = :status
            instance.handle_authentication()
          end

          def redirect_url_with_cas_authentication(controller, url)
            instance = new(controller)
            instance.do_redirect = false
            instance.handle_gatewaying = false
            instance.returning = :url
            instance.service_url = url
            instance.handle_authentication()
          end

          def configure(config)
            @@config = config
            impl_class = config.delete(:filter_implementation)
            @@locale_callback = config.delete(:locale_callback) || :cas_locale
            @@user_prefill_callback = config.delete(:user_prefill_callback) || :cas_user_prefill
            case impl_class
            when "CookieSessionFilterImplementation"              
              require 'casclient/frameworks/rails/cookie_session_filter_implementation'
              @@impl = CASClient::Frameworks::Rails::CookieSessionFilterImplementation.new(config)
            else
              require 'casclient/frameworks/rails/default_filter_implementation'
              @@impl = CASClient::Frameworks::Rails::DefaultFilterImplementation.new(config)
            end
            
            @@config[:logger] = RAILS_DEFAULT_LOGGER unless @@config[:logger]
            @@client = CASClient::Client.new(config)
            @@log = client.log
            @@impl.log = client.log
            @@impl.client = client
          end
          
          def reset!
            @@config = nil
            @@locale_callback = nil
            @@user_prefill_callback = nil
            @@impl = nil
            @@client = nil
            @@log = nil
          end
        
          def use_gatewaying?
            config[:use_gatewaying]
          end
          
          def check_cas_status?
            config[:check_cas_status]
          end
          
          def ignore_cas_down_in_gateway?
            config[:ignore_cas_down_in_gateway]
          end
          
          def cas_down_redirect_to
            config[:cas_down_redirect_to]
          end
          
          
          # Clears the given controller's local Rails session, does some local 
          # CAS cleanup, and redirects to the CAS logout page. Additionally, the
          # <tt>request.referer</tt> value from the <tt>controller</tt> instance 
          # is passed to the CAS server as a 'service' parameter. This 
          # allows RubyCAS server to provide a follow-up login page allowing
          # the user to log back in to the service they just logged out from 
          # using a different username and password. Other CAS server 
          # implemenations may use this 'service' parameter in different 
          # ways. 
          # If given, the optional <tt>service</tt> URL overrides 
          # <tt>request.referer</tt>.
          def logout(controller, referer = nil)
            log.debug("cas filter logout called")
            referer ||= controller.request.referer
            st = impl.read_last_service_ticket(controller)
            impl.delete_service_session_lookup(controller, st) if st
            controller.send(:reset_session)
            controller.send(:redirect_to, client.logout_url(referer))
          end
          
        end

        def initialize(controller)
          @controller = controller
        end
        
        def log; self.class.log; end

        def client; self.class.client; end

        def config; self.class.config; end

        def impl; self.class.impl; end

        def cas_down_redirect_page; self.class.impl; end

        def locale_callback; self.class.locale_callback; end

        def user_prefill_callback; self.class.user_prefill_callback; end
        
        def add_locale?
          client && client.add_locale?
        end
        
        def user_prefill?
          client && client.user_prefill? && controller.respond_to?(user_prefill_callback)
        end
        
        def check_cas_status?; self.class.check_cas_status?; end
        
        def use_gatewaying?(controller)
          if controller.respond_to?(:force_login?)
            return false if controller.send(:force_login?)
          end
          self.class.use_gatewaying?
        end

        def returns_url?
          @returning == :url
        end

        # This method does the work of CAS authentication. 
        # This method is not called directly, but is called by the class methods +filter+ or 
        # +redirect_url_with_cas_authentication+, which create and configure an instance
        # and then call this method on it.
        # 
        # 
        # 
        # ==== Returns
        # The return value depends on the setting of ++returning++.
        #  
        # Boolean:: when +returning+ == +:status+. For normal filter, returns true if the user
        #    is authenticated, false if not. For gateway filter, always returns true.
        #    If the user is not logged in, calls redirect_to_cas_for_authentication
        # String:: when +returning+ == +:url+. Returns the redirect url for cas if the user is
        #    not authenticated, and the service url if they are
        def handle_authentication()
          log.debug "cas filter. #{self.class.name}"
          raise "Cannot use the CASClient filter because it has not yet been configured." if config.nil?
          
          if check_cas_status?
            log.debug "checking cas status"
            # begin
              res = client.check_cas_status
              log.debug "got #{res} from check_cas_status"
            # rescue 
            #   if cas_down_redirect_page
            #     controller.redirect_to cas_down_redirect_page
            #   else
            #     raise
            #   end
            # end
          end
          
          log.debug "calling single_sign_out"
          # single sign out requests have to come to the original service_url, but we don't want to actually handle them as a normal app request
          if single_sign_out(controller)
            raise "received single_signout but filter was in returns_url mode" if returns_url?
            return false
          end

          log.debug "call read_last_service_ticket"
          last_st = impl.read_last_service_ticket(controller)
          log.debug "got last_st: #{last_st.inspect}"
          
          log.debug "read ticket from controller"
          st = read_ticket(controller)
          
          if st && last_st && 
              last_st.ticket == st.ticket && 
              last_st.service == st.service
            # warn() rather than info() because we really shouldn't be re-validating the same ticket. 
            # The only situation where this is acceptable is if the user manually does a refresh and 
            # the same ticket happens to be in the URL.
            log.debug("Re-using previously validated ticket since the ticket id and service are the same.")
            log.warn("Re-using previously validated ticket since the ticket id and service are the same.")
            st = last_st
          elsif last_st &&
              !config[:authenticate_on_every_request] && 
              impl.has_cas_user?(controller)
            # Re-use the previous ticket if the user already has a local CAS session (i.e. if they were already
            # previously authenticated for this service). This is to prevent redirection to the CAS server on every
            # request.
            # This behaviour can be disabled (so that every request is routed through the CAS server) by setting
            # the :authenticate_on_every_request config option to false. 
            log.debug "Existing local CAS session detected for #{controller.session[client.username_session_key].inspect}. "+
              "Previous ticket #{last_st.ticket.inspect} will be re-used."
            st = last_st
          end
          
          log.debug "check if we have a ticket at this point"

          if st
            log.debug "we have a ticket: #{st.ticket}"
            client.validate_service_ticket(st) unless st.has_been_validated?
            validation_response = st.response
            if st.is_valid?
              log.info("Ticket #{st.ticket.inspect} for service #{st.service.inspect} belonging to user #{validation_response.user.inspect} is VALID.")
              controller.session[client.username_session_key] = validation_response.user
              extra_attributes = validation_response.extra_attributes
              extra_attributes &&= extra_attributes.with_indifferent_access
              controller.session[client.extra_attributes_session_key] = extra_attributes
              
              # RubyCAS-Client 1.x used :casfilteruser as it's username session key,
              # so we need to set this here to ensure compatibility with configurations
              # built around the old client.
              # controller.session[:casfilteruser] = validation_response.user
              
              # Store the ticket in the session to avoid re-validating the same service
              # ticket with the CAS server. 
              impl.write_last_service_ticket(controller, st) unless  last_st && (st.ticket == last_st.ticket)
              
              if validation_response.pgt_iou
                log.info("Receipt has a proxy-granting ticket IOU. Attempting to retrieve the proxy-granting ticket...")
                pgt = client.retrieve_proxy_granting_ticket(validation_response.pgt_iou)
                if pgt
                  log.debug("Got PGT #{pgt.ticket.inspect} for PGT IOU #{pgt.iou.inspect}. This will be stored in the session.")
                  controller.session[:cas_pgt] = pgt
                  # For backwards compatibility with RubyCAS-Client 1.x configurations...
                  controller.session[:casfilterpgt] = pgt
                else
                  log.error("Failed to retrieve a PGT for PGT IOU #{validation_response.pgt_iou}!")
                end
              end
              
              impl.store_service_session_lookup(st, controller)
             
              return (returns_url? ? service_url : true)
            else
              log.warn("Ticket #{st.ticket.inspect} failed validation -- #{validation_response.failure_code}: #{validation_response.failure_message}")
              redirect_url = redirect_to_cas_for_authentication
              impl.clear_cas_user!(controller)
              return (returns_url? ? redirect_url : true)
            end
          else
            log.debug "we don't have a ticket."
            log.debug "clearing any stale user"
            impl.clear_cas_user!(controller)
            log.debug "check if returning from gateway"
            if handle_gatewaying && returning_from_gateway?(controller)
              log.info "Returning from CAS gateway without authentication."
              log.debug "Returning from CAS gateway without authentication."
              
              if use_gatewaying?(controller)
                log.info "This CAS client is configured to use gatewaying, so we will permit the user to continue without authentication."
                return (returns_url? ? service_url : true)
              else
                log.warn "The CAS client is NOT configured to allow gatewaying, yet this request was gatewayed. Something is not right!"
              end
            end
            
            redirect_url = redirect_to_cas_for_authentication
            return (returns_url? ? redirect_url : false)
          end
        end
        
        # Creates an url to cas login with the specified or default service_url returning
        # back to the application. If +use_gatewaying?+ is true, it appends the <tt>gateway=true</tt>
        # param, and sets <tt>session[:cas_sent_to_gateway]</tt> to true. It also avoids redirection
        # looks by using a timestamp in <tt>session[:previous_redirect_to_cas]</tt>. If it detects
        # a redirection loop it forces a renew at the CAS server by appending <tt>renew=1</tt>
        def redirect_to_cas_for_authentication
          log.debug("redirect_to_cas_for_authentication")
          service_url ||= read_service_url(controller)
          redirect_url = client.add_service_to_login_url(service_url)

          if add_locale?
            locale = controller.send(locale_callback)
            redirect_url = client.add_locale_to_url(redirect_url, locale) unless locale.blank?
          end
          
          if user_prefill?
            user_prefill = controller.send(user_prefill_callback)
            redirect_url = client.add_user_prefill_to_url(redirect_url, user_prefill) unless user_prefill.blank?
          end
          
          if use_gatewaying?(controller)
            log.debug "adding gateway=true to redirect"
            controller.session[:cas_sent_to_gateway] = true
            redirect_url << "&gateway=true"
          else
            controller.session[:cas_sent_to_gateway] = false
          end
          
          if controller.session[:previous_redirect_to_cas] &&
              controller.session[:previous_redirect_to_cas] > (Time.now - 1.second)
            log.warn("Previous redirect to the CAS server was less than a second ago. The client at #{controller.request.remote_ip.inspect} may be stuck in a redirection loop!")
            controller.session[:cas_validation_retry_count] ||= 0
            
            if controller.session[:cas_validation_retry_count] > 3
              log.error("Redirection loop intercepted. Client at #{controller.request.remote_ip.inspect} will be redirected back to login page and forced to renew authentication.")
              redirect_url += "&renew=1&redirection_loop_intercepted=1"
            end
            
            controller.session[:cas_validation_retry_count] += 1
          else
            log.debug "incrementing cas_validation_retry_count"
            controller.session[:cas_validation_retry_count] = 0
          end
          controller.session[:previous_redirect_to_cas] = Time.now
          
          log.debug("Redirecting to #{redirect_url.inspect}")
          controller.send(:redirect_to, redirect_url) unless returns_url?
          redirect_url
        end
        
        private
        # detects a logout request by the presence of a +logoutRequest+ param,
        # and calls <tt>impl.perform_sign_out</tt> if it is present.
        def single_sign_out(controller)
          log.debug "single_sign_out called"
          log.debug "controller.params[:logoutRequest]: #{controller.params[:logoutRequest].inspect}"
          if controller.request.post? &&
              controller.params[:logoutRequest] &&
              controller.params[:logoutRequest] =~ 
                /^<samlp:LogoutRequest.*?<samlp:SessionIndex>(.*)<\/samlp:SessionIndex>/m
            # TODO: Maybe check that the request came from the registered CAS server? Although this might be
            #       pointless since it's easily spoofable...
            service_ticket_id = $~[1]
            log.debug "Intercepted logout request for CAS session #{service_ticket_id.inspect}."
            impl.perform_sign_out(service_ticket_id)
          else
            return false
          end
        end
        
        # Looks for a ticket param on the controller. If it is present, creates a ticket object.
        # Creates a +ProxyTicket+ if the ticket param begins with PT-, else creates a +ServiceTicket+
        def read_ticket(controller)
          log.debug("read ticket")
          ticket = controller.params[:ticket]
          
          return nil unless ticket
          
          log.debug("Request contains ticket #{ticket.inspect}.")
          
          if ticket =~ /^PT-/
            log.debug("creating proxy ticket")
            ProxyTicket.new(ticket, read_service_url(controller), controller.params[:renew])
          else
            log.debug("creating service ticket")
            ServiceTicket.new(ticket, read_service_url(controller), controller.params[:renew])
          end
        end
        
        # returns true if +session[:cas_sent_to_gateway]+ is set, and then sets it to false
        def returning_from_gateway?(controller)
          result = controller.session[:cas_sent_to_gateway]
          controller.session[:cas_sent_to_gateway] = false
          result
        end
        
        # returns the service_url set on the filter if it is set. If it is blank,
        # constructs a service_url, by sending +cas_service_url+ to +controller+
        # If +controller+ does not respond_to? +cas_service_url+, calls <tt>controller.url_for</tt>
        # with the current +controller+ params after deleting the +ticket+ param.
        def read_service_url(controller)
          if @service_url
            return service_url
          elsif config[:service_url]
            return config[:service_url]
          end
          
          params = controller.params.dup
          params.delete(:ticket)
          if(controller.respond_to?(:cas_service_url))
            service_url = controller.send(:cas_service_url, params)
          else
            service_url = controller.url_for(params)
          end
          log.debug("read_service_url: returning #{service_url}")
          return service_url
        end
        
        # redirects to the specified url / action when the cas server is unavailable
        def redirect_to_cas_down
          if cas_down_redirect_page
            controller.redirect_to cas_down_redirect_page
            return false
          else
            log.warn("no cas_down_redirect_page page set; ignoring cas down error")
            return true
          end
        end

      end
    
      class GatewayFilter < Filter
        def self.use_gatewaying?
          log.debug "using gatewaying: #{!(@@config[:use_gatewaying] == false)}"
          return true unless @@config[:use_gatewaying] == false
        end
      end
    end
  end
end