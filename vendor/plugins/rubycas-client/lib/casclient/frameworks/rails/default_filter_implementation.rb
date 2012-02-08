module CASClient
  module Frameworks
    module Rails
      class DefaultFilterImplementation
        attr_accessor :log, :config, :client
        
        def initialize(config={})
          @config = config
        end
        
        def perform_sign_out(service_ticket_id)
          required_sess_store = CGI::Session::ActiveRecordStore
          current_sess_store  = ActionController::Base.session_options[:database_manager]
          
          if current_sess_store == CGI::Session::ActiveRecordStore
            session_id = read_service_session_lookup(service_ticket_id)
            session = CGI::Session::ActiveRecordStore::Session.find_by_session_id(session_id)
            session.destroy
            log.debug("Destroyed session id #{session_id.inspect} corresponding to service ticket #{service_ticket_id.inspect}.")
            
            return true
          else
            log.error "Cannot process logout request because this Rails application's session store is "+
              " #{current_sess_store.name.inspect}. Single Sign-Out only works with the "+
              " #{required_sess_store.name.inspect} session store."
            
            return false
          end
        end
        
        def read_last_service_ticket(controller)
          controller.session[:cas_last_valid_ticket]
        end
        
        def write_last_service_ticket(controller, st)
          controller.session[:cas_last_valid_ticket] = st
        end
        
        # Creates a file in tmp/sessions linking a SessionTicket
        # with the local Rails session id. The file is named
        # cas_sess.<session ticket> and its text contents is the corresponding 
        # Rails session id.
        # Returns the filename of the lookup file created.
        def store_service_session_lookup(st, controller)
          sid = controller.session.session_id
          st = st.ticket if st.kind_of? ServiceTicket
          f = File.new(filename_of_service_session_lookup(st), 'w')
          f.write(sid)
          f.close
          log.debug("Wrote service session lookup file to #{filename_of_service_session_lookup(st).inspect} with session id #{sid}.")
        end

        # Returns true if the controller is currently aware of an (authenticated) cas_user
        # This is used when authenticate_on_every_request is false
        def has_cas_user?(controller)
          controller.session[client.username_session_key]
        end

        # Clears the cas user (& extra attributes) from the session. This
        # is called if the session has a cas ticket that fails to validate
        def clear_cas_user!(controller)
          controller.session[client.username_session_key] = nil
          controller.session[client.extra_attributes_session_key] = nil
        end
        
        # Returns the local Rails session ID corresponding to the given
        # ServiceTicket. This is done by reading the contents of the
        # cas_sess.<session ticket> file created in a prior call to 
        # #store_service_session_lookup.
        def read_service_session_lookup(st)
          st = st.ticket if st.kind_of? ServiceTicket
          return IO.read(filename_of_service_session_lookup(st))
        end
        
        # Removes a stored relationship between a ServiceTicket and a local
        # Rails session id. This should be called when the session is being
        # closed.
        #
        # See #store_service_session_lookup.
        def delete_service_session_lookup(controller, st)
          st = st.ticket if st.kind_of? ServiceTicket
          File.delete(filename_of_service_session_lookup(st))
        end
        
        # Returns the path and filename of the service session lookup file.
        # The returned path is relative, starting at RAILS_ROOT, so you may
        # need to prepend RAILS_ROOT to the return value and/or call
        # File.expand_path.
        def filename_of_service_session_lookup(st)
          st = st.ticket if st.kind_of? ServiceTicket
          return "tmp/sessions/cas_sess.#{st}"
        end

      end
    end
  end
end