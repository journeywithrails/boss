require File.dirname(__FILE__) + '/../test_helper'

class RubyCasClientTest < ActiveSupport::TestCase

  def setup
    
    @impl = CASClient::Frameworks::Rails::CookieSessionFilterImplementation.new
    @impl.log = RAILS_DEFAULT_LOGGER
    @controller = mock()
    client = mock()
    client.stubs(:username_session_key).returns(:sage_user)
    client.stubs(:extra_attributes_session_key).returns(:cas_extra_attributes)
    @impl.client = client
  end
  
  def teardown
  end
  
  def test_read_last_service_ticket_returns_nil_if_no_last_valid_ticket_in_session
    @controller.expects(:session).returns({})
    @impl.expects(:clear_stale_session).with(@controller).never

    assert_nil @impl.read_last_service_ticket(@controller)
  end

  def test_read_last_service_ticket_returns_nil_and_clears_session_if_no_cas_service_ticket
    @controller.expects(:session).returns({:cas_last_valid_ticket => 'bob-the-ticket'})    
    @impl.expects(:clear_stale_session).with(@controller).once

    assert_nil @impl.read_last_service_ticket(@controller)
  end

  def test_read_last_service_ticket_returns_adapted_service_ticket_if_cas_service_ticket
    cst = create_valid_cas_service_ticket({:st_id => 'bob-the-ticket'})
    @controller.expects(:session).returns({:cas_last_valid_ticket => cst.id})
    
    ticket = @impl.read_last_service_ticket(@controller)
    
    assert_not_nil ticket
    assert ticket.is_a?(CASClient::ServiceTicket)
    assert_equal 'bob-the-ticket', ticket.ticket
    assert_equal 'a-service-url', ticket.service
  end


  def test_clear_stale_session
    session = {:cas_last_valid_ticket => 'bob-the-ticket', 
      :sage_user => 'bob',
      :cas_extra_attributes => 'stuff'}
    @controller.expects(:session).at_least_once.returns(session)
    
    @impl.clear_stale_session(@controller)
    
    assert_nil session[:cas_last_valid_ticket]
    assert_nil session[:sage_user]
    assert_nil session[:cas_extra_attributes]
  end
  
  def test_write_last_service_ticket_raises_if_cant_call_user_id_for_cas_user
    assert_raises RuntimeError, "Can't use CookieSessionFilterImplementation because controller doesn't understand user_id_for_cas_user" do
      @impl.write_last_service_ticket(@controller, create_valid_service_ticket)
    end
  end


  def test_write_last_service_ticket_logs_error_if_no_user_id
    @controller.stubs(:session).returns({})
    @controller.stubs(:user_id_for_cas_user).returns(nil)
    log = mock()
    log.expects(:error)
    log.stubs(:debug)
    @impl.log = log
    @impl.write_last_service_ticket(@controller, create_valid_service_ticket)
  end
  
  def test_write_last_service_ticket_adds_ticket_id_to_session_and_saves_cas_service_ticket
    CasServiceTicket.delete_all
    session = {}
    @controller.expects(:session).at_least_once.returns(session)
    @controller.stubs(:user_id_for_cas_user).returns(users(:basic_user).id)
    service_ticket = create_valid_service_ticket(:sage_user => 'basic_user')
    assert_difference('CasServiceTicket.count', 1) do
      st = @impl.write_last_service_ticket(@controller, service_ticket)
    end
    cas_service_ticket = CasServiceTicket.find(:first)
    assert_equal cas_service_ticket.id, session[:cas_last_valid_ticket]
    assert_equal service_ticket.ticket, cas_service_ticket.st_id
    assert_equal users(:basic_user).id, cas_service_ticket.user_id
    assert_equal service_ticket.service, cas_service_ticket.service
    assert_equal service_ticket.response, cas_service_ticket.response
  end

  def test_perform_sign_out_raises_if_not_cookie_store
    ActionController::Base.expects(:session_options).returns({:database_manager => Hash})
    exception = assert_raise RuntimeError do
      @impl.perform_sign_out('bob')
    end
    assert_match /Cannot process logout request/, exception.message
  end
  
  def test_perform_sign_out
    create_valid_cas_service_ticket(:st_id => 'ticket-a')
    create_valid_cas_service_ticket(:st_id => 'ticket-b')
    create_valid_cas_service_ticket(:st_id => 'ticket-b', :user_id => '66')
    create_valid_cas_service_ticket(:st_id => 'ticket-c', :user_id => '66')
    assert_difference('CasServiceTicket.count', -2) do
      @impl.perform_sign_out('ticket-a')
    end
    assert CasServiceTicket.exists?(:st_id => 'ticket-c')
    assert CasServiceTicket.exists?(:st_id => 'ticket-b')
    deny CasServiceTicket.exists?(:st_id => 'ticket-b', :user_id => '77')
    deny CasServiceTicket.exists?(:st_id => 'ticket-a', :user_id => '77')
  end
  
  def test_perform_sign_out_does_nothing_if_ticket_not_existing
    create_valid_cas_service_ticket(:st_id => 'ticket-b')
    create_valid_cas_service_ticket(:st_id => 'ticket-b', :user_id => '66')
    create_valid_cas_service_ticket(:st_id => 'ticket-c', :user_id => '66')
    assert_no_difference('CasServiceTicket.count') do
      @impl.perform_sign_out('ticket-a')
    end
  end
  
  def test_delete_service_session_lookup
    st = create_valid_service_ticket(:ticket => 'ticket-a')
    create_valid_cas_service_ticket(:st_id => 'ticket-a')
    create_valid_cas_service_ticket(:st_id => 'ticket-b')
    create_valid_cas_service_ticket(:st_id => 'ticket-b', :user_id => '66')
    create_valid_cas_service_ticket(:st_id => 'ticket-c', :user_id => '66')
    assert_difference('CasServiceTicket.count', -2) do
      @impl.delete_service_session_lookup(@controller, st)
    end
    assert CasServiceTicket.exists?(:st_id => 'ticket-c')
    assert CasServiceTicket.exists?(:st_id => 'ticket-b')
    deny CasServiceTicket.exists?(:st_id => 'ticket-b', :user_id => '77')
    deny CasServiceTicket.exists?(:st_id => 'ticket-a', :user_id => '77')
  end
  
  def test_create_or_update_cas_service_ticket_with_service_ticket
    st = create_valid_service_ticket
    cas_service_ticket = nil
    assert_difference "CasServiceTicket.count", 1 do
      cas_service_ticket = @impl.create_or_update_cas_service_ticket(st, 77)
    end
    assert_equal('CASClient::ServiceTicket', cas_service_ticket.cas_ticket_type)
    assert_equal(st.service, cas_service_ticket.service)
    assert_equal(st.response, cas_service_ticket.response)
    assert_equal(st.renew, cas_service_ticket.renew)
  end
  
  def test_create_or_update_cas_service_ticket_with_proxy_ticket
    st = create_valid_proxy_ticket
    cas_service_ticket = nil
    assert_difference "CasServiceTicket.count", 1 do
      cas_service_ticket = @impl.create_or_update_cas_service_ticket(st, 77)
    end
    assert_equal('CASClient::ProxyTicket', cas_service_ticket.cas_ticket_type)
    assert_equal(st.service, cas_service_ticket.service)
    assert_equal(st.response, cas_service_ticket.response)
    assert_equal(st.renew, cas_service_ticket.renew)
  end
  
  def test_create_or_update_cas_service_ticket_with_proxy_granting_ticket
    st = create_valid_proxy_granting_ticket
    cas_service_ticket = nil
    assert_difference "CasServiceTicket.count", 1 do
      cas_service_ticket = @impl.create_or_update_cas_service_ticket(st, 77)
    end
    assert_equal('CASClient::ProxyGrantingTicket', cas_service_ticket.cas_ticket_type)
    assert_equal(st.iou, cas_service_ticket.pgt_iou)
  end
  
  def test_is_success_works_after_round_trip
    @controller.stubs(:user_id_for_cas_user).returns(nil)
    @controller.stubs(:session).returns({})
    response = CASClient::ValidationResponse.new(valid_cas_response_xml)
    service_ticket = create_valid_service_ticket(:response => response)
    @impl.write_last_service_ticket(@controller, service_ticket)
    service_ticket = @impl.read_last_service_ticket(@controller)
    assert_nothing_raised do
      service_ticket.response.is_success?
    end
    assert service_ticket.response.is_success?
    deny service_ticket.response.is_failure?
  end
  
  def create_valid_cas_service_ticket(options={})
    c = CasServiceTicket.create(
      {
        :st_id => 'a-ticket-id',
        :user_id => '77',
        :service => 'a-service-url',
        :response => 'a-response-body',
        :cas_ticket_type => 'CASClient::ServiceTicket'
      }.merge(options)
    )
    c
  end
  
  def create_valid_service_ticket(options={})
    options[:ticket] ||= 'a-valid-ticket'
    options[:service] ||= 'another-service'
    options[:renew] ||= false
    options[:sage_user] || 'some-guy'
    options[:response] ||= OpenStruct.new(:user => options[:sage_user])
    
    st = CASClient::ServiceTicket.new(options[:ticket], options[:service], options[:renew])
    st.response = options[:response]
    st
  end

  def create_valid_proxy_ticket(options={})
    options[:ticket] ||= 'a-valid-ticket'
    options[:service] ||= 'another-service'
    options[:renew] ||= false
    options[:response] ||= OpenStruct.new
    options[:response].user = options[:sage_user] || 'some-guy'
    
    st = CASClient::ProxyTicket.new(options[:ticket], options[:service], options[:renew])
    st.response = options[:response]
    st
  end

  def create_valid_proxy_granting_ticket(options={})
    options[:ticket] ||= 'a-valid-ticket'
    options[:service] ||= 'another-service'
    options[:renew] ||= false
    options[:sage_user] ||= 'some-guy'
    options[:response] ||= OpenStruct.new(:user => options[:sage_user])
    options[:pgt_iou] = 'an-iou'
    st = CASClient::ProxyGrantingTicket.new(options[:ticket], options[:pgt_iou])
    st
  end

  def valid_cas_response_xml
    <<-EOQ
    <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
      <cas:authenticationSuccess>
        <cas:user>lastobelus</cas:user>
        <created_at>2009-03-30 20:55:19.0</created_at>

        <username>
                bobby
        </username>

        <email>
                bobby@billingboss.com
        </email>

        <source>
                sagespark/reg33109
        </source>

        <profile>
                business
        </profile>

        <first_name>
                Bob
        </first_name>
      </cas:authenticationSuccess>
    </cas:serviceResponse>"
    EOQ
  end
if false  
end  
  
end
