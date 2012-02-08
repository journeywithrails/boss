module CASClient
  module Frameworks
    module Rails
      class CookieSessionFilterImplementation
        attr_accessor :log, :config, :client
        
        def initialize(config={})
          @config = config
        end
        
        # in this model, perform_sign_out & delete_service_session_lookup are identical
        def perform_sign_out(service_ticket_id)
          log.debug "perform_sign_out"
          required_sess_store = CGI::Session::CookieStore
          current_sess_store  = ActionController::Base.session_options[:database_manager]
          
          if current_sess_store == required_sess_store
            remove_all_service_tickets_for_user(service_ticket_id)
            return true
          else
            raise "Cannot process logout request because this Rails application's session store is "+
              " #{current_sess_store.name.inspect}. Single Sign-Out only works with the "+
              " #{required_sess_store.name.inspect} session store."            
          end
        end
        
        
        # WARN: possibly expensive, may be optimization point
        def read_last_service_ticket(controller)
          log.debug "read_last_service_ticket"
          st_id = controller.session[:cas_last_valid_ticket]
          if st_id
            log.debug "found last ticket #{st_id} in session"
            cas_service_ticket = get_cas_service_ticket(st_id)
            log.debug "looked for cas_service_ticket with st_id #{st_id}, found: #{cas_service_ticket.inspect}"
            if cas_service_ticket
              return service_ticket_from_cas_service_ticket(cas_service_ticket)
            else
              clear_stale_session(controller)
              return nil
            end
          end
          nil
        end
        
        def clear_stale_session(controller)
          controller.session[:cas_last_valid_ticket] = nil
          controller.session[client.username_session_key] = nil
          controller.session[client.extra_attributes_session_key] = nil
        end
        
        def write_last_service_ticket(controller, st)
          raise "Can't use CookieSessionFilterImplementation because controller doesn't understand user_id_for_cas_user" unless controller.respond_to?(:user_id_for_cas_user)
          raise "Ticket #{st} has no response set yet" if st.response.nil?
          cas_user = st.response.user
          extra_attributes = st.response.extra_attributes
          extra_attributes &&= extra_attributes.with_indifferent_access
          
          user_id = controller.send(:user_id_for_cas_user, cas_user, extra_attributes)
          if user_id.nil?
            log.error "can't establish relationship between service ticket and user because user_id_for_cas_user(#{cas_user}) returned nil"
          end
          log.debug "write_last_service_ticket #{st.inspect}"
          cas_service_ticket = create_or_update_cas_service_ticket(st, user_id)
          controller.session[:cas_last_valid_ticket] = cas_service_ticket.id
          st
        end
        
        # In the default implementation, creates a file in tmp/sessions linking 
        # a SessionTicket with the local Rails session id. The file is named
        # cas_sess.<session ticket> and its text contents is the corresponding 
        # Rails session id.
        # Here, we do nothing as cas_service_ticket which should already exist having 
        # been created in write_last_service_ticket
        def store_service_session_lookup(st, controller)
        end
        
        # Removes a stored relationship between a ServiceTicket and a local
        # Rails session id. This should be called when the session is being
        # closed.
        #
        # See #store_service_session_lookup.
        def delete_service_session_lookup(controller, st)
          remove_all_service_tickets_for_user(st.ticket)
        end
        
        def remove_all_service_tickets_for_user(st_id)
          log.debug "delete_service_session_lookup. deleting all cst with st_id = #{st_id}"
          cas_service_tickets = CasServiceTicket.find(:all, :conditions => {:st_id => st_id})
          user_ids = cas_service_tickets.collect{|cas_service_ticket| cas_service_ticket.user_id}
          user_ids.uniq.compact.each do |user_id|
            CasServiceTicket.delete_all(['user_id = ?', user_id])
          end
          CasServiceTicket.delete_all(['st_id = ?', st_id])
        end
        
        def get_cas_service_ticket(id)
          cas_service_ticket = CasServiceTicket.find_by_id(id)
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
        
        def create_or_update_cas_service_ticket(st, user_id)
          st_id = st.ticket
          cas_service_ticket = CasServiceTicket.find_by_st_id(st_id)
          cas_service_ticket ||= CasServiceTicket.new(:st_id => st_id, :user_id => user_id)
          case st
          when CASClient::ServiceTicket
            cas_service_ticket.service = st.service
            cas_service_ticket.renew = st.renew
            cas_service_ticket.response = st.response
          when CASClient::ProxyGrantingTicket
            cas_service_ticket.pgt_iou = st.iou if st.respond_to?(:iou)
          end
          cas_service_ticket.cas_ticket_type = st.class.name
          cas_service_ticket.save!
          cas_service_ticket
        end
        
        def service_ticket_from_cas_service_ticket(cas_service_ticket)
          st = case cas_service_ticket.cas_ticket_type
            when "CASClient::ServiceTicket"
              CASClient::ServiceTicket.new(cas_service_ticket.st_id, cas_service_ticket.service, cas_service_ticket.renew)
            when "CASClient::ProxyTicket"
              CASClient::ProxyTicket.new(cas_service_ticket.st_id, cas_service_ticket.service, cas_service_ticket.renew)
            when "CASClient:ProxyGrantingTicket"
              CASClient::ProxyGrantingTicket.new(cas_service_ticket.st_id, cas_service_ticket.pgt_iou)
            end
          st.response = cas_service_ticket.response
          st
        end
      end
    end
  end
end