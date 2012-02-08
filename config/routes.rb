def with_api_options(options={})
  name_prefix = options[:name_prefix] || ""
  path_prefix = options[:path_prefix].blank? ? "" : "/#{options[:path_prefix]}"
  options.merge(:name_prefix => "api_#{name_prefix}", :path_prefix => "api/simply#{path_prefix}")
end

def resources_with_api_options(map, resource, options={})
  map.resources(resource, options)
  map.resources(resource, with_api_options(options))
end

ActionController::Routing::Routes.draw do |map|

  map.resources :languages

  map.connect 'languages/:id', :controller => 'languages', :action => 'show'
  map.lang '/de', :controller => 'languages', :action => 'show', :id => 'de'
  map.lang '/en', :controller => 'languages', :action => 'show', :id => 'en'
  map.lang '/es', :controller => 'languages', :action => 'show', :id => 'es'
  map.lang '/fr', :controller => 'languages', :action => 'show', :id => 'fr'
  map.lang '/gu', :controller => 'languages', :action => 'show', :id => 'gu'
  map.lang '/hi', :controller => 'languages', :action => 'show', :id => 'hi'
  map.lang '/it', :controller => 'languages', :action => 'show', :id => 'it'
  map.lang '/ko', :controller => 'languages', :action => 'show', :id => 'ko'
  map.lang '/pt', :controller => 'languages', :action => 'show', :id => 'pt'
  map.lang '/pt_BR', :controller => 'languages', :action => 'show', :id => 'pt_BR'
  map.lang '/ru', :controller => 'languages', :action => 'show', :id => 'ru'
  map.lang '/zh', :controller => 'languages', :action => 'show', :id => 'zh_CN'
  map.lang '/zh_CN', :controller => 'languages', :action => 'show', :id => 'zh_CN'
  map.lang '/zh_HK', :controller => 'languages', :action => 'show', :id => 'zh_HK'
  map.lang '/zh_TW', :controller => 'languages', :action => 'show', :id => 'zh_TW'
  
  map.resources :browsals, :controller => 'new_browsals', :member => {
    :signup => :get,
    :login => :get,
    :send_invoice => :get,
  }
  
  resources_with_api_options map, :browsals, :controller => 'new_browsals', :member => {
    :signup => :get,
    :login => :get,
    :send_invoice => :get,
  }
  

  map.sso_signup '/signup', :controller => 'users', :action => 'signup'
  
  map.resource :admin do |admin| 
    admin.resources :roles, :name_prefix => 'admin_', :controller => 'admin/roles'
  end

  map.resources :taxes

  # map.resources :bookkeeping_clients, :has_many => [:reports]
  map.resources :bookkeeping_clients do |bookkeeping_client|
    bookkeeping_client.resources :reports, :member => {:print => :get}
  end

  map.resources :bookkeepers

  map.resources :reports, :member => {:print => :get}
  map.threef '/user_gateways/threef', :controller => 'user_gateways', :action => 'threef'

  map.resources :user_gateways, :collection => {:switch_to_sps => :get}
# , :member=>{:help => :get}
  # map.user_gateway '/user_gateways/:id', :controller => 'user_gateways', :action => 'show'

  map.accept_invitation  '/invitations/:id/accept', :controller => 'invitations', :action => 'accept'
  map.decline_invitation '/invitations/:id/decline', :controller => 'invitations', :action => 'decline'
  map.resources :invitations #, :member => {:accept => :post, :decline => :post}
  map.resources :offers # received invitations

  map.resources :deliveries, :collection => {:unable => :get}, :member => {:unable => :get}

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.namespace :admin do |admin|
     admin.resources :feedback
     admin.resources :winners
  end 

  resources_with_api_options map, :users, :collection => {:communications => :get}, :member => {:thankyou => :get}
  map.thankyou_service "newuser/thankyou", :controller => "users", :action => 'thankyou'
  map.api_thankyou_service "newuser/thankyou", :controller => "users", :action => 'thankyou', :path_prefix => "api/simply"
  
  map.namespace :service_provider do |service_provider|
    service_provider.resources :spaccounts
    service_provider.resources :spaccounts, :has_many => [:spsubscriptions]

    service_provider.resources :spsubscriptions  
  end 
  
  map.resources :customers, :has_many => [:contacts, :invoices],
    :collection => {:overview => :get, :details => :get, :filter => :put}
  map.resources :invoices, :has_many => [:line_items, :payments], 
      :member => {
          :recalculate => :post, :invoice_status => :get, :mark_printed => :put, 
          :mark_sent => :put, :update_payment_methods => :put, 
          :convert_quote => :put, :create_recurring_form => :get, :create_recurring => :put,
          :display_invoice => :get, :generated => :get },  #RADAR status is reserved
      :new => {:recalculate => :post}, 
      :collection => {:overview => :get, :filter => :put, :recurring => :get} do |invoice|
    invoice.resources :online_payments,
      :collection => {
        :confirm => :get, # paypal
        :complete => :get, # paypal
        :cancel => :get,  # paypal
        :retry => :get,
        :payment_type => :post
      }
  end

  # The docs don't make it clear if the request will be a get or a post, so accept both.
  map.beanstream_interac_approved_invoice_online_payments 'invoices/:invoice_id/online_payments/beanstream_interac_approved', :controller => 'online_payments', :action => 'beanstream_interac_approved'
  map.beanstream_interac_declined_invoice_online_payments 'invoices/:invoice_id/online_payments/beanstream_interac_declined', :controller => 'online_payments', :action => 'beanstream_interac_declined'
  map.interac 'interac', :controller => 'online_payments', :action => 'interac'
  # These funded and notfunded urls are apparently required by interac. Even
  # though I created and send the above secure urls these ones are the ones
  # that are actually returned.
  map.interac_funded 'interac/funded', :controller => 'online_payments', :action => 'interac_funded'
  map.interac_notfunded 'interac/notfunded', :controller => 'online_payments', :action => 'interac_notfunded'

  map.resources :payments
  
  map.resource :session, :controller => 'session', :member => {:logged_on => :get}
  map.resource :session, with_api_options(:controller => 'session', :member => {:logged_on => :get})

  map.resource :session, with_api_options(:controller => 'session')
#  map.resources :profiles
  #only allow one action

  map.addressing_settings '/addressing_settings', :controller => 'profiles', :action => 'edit', :setting => 'addressing'
  map.tax_settings '/tax_settings', :controller => 'profiles', :action => 'edit', :setting => 'taxes'
  map.logo_settings '/logo_settings', :controller => 'profiles', :action => 'edit', :setting => 'logo'
  map.communication_settings '/communication_settings', :controller => 'profiles', :action => 'edit', :setting => 'communications'
  map.online_payments_settings '/online_payments_settings', :controller => 'profiles', :action => 'edit', :setting => 'payments'
  
  map.about '/about', :controller => 'home', :action => 'about'
  map.faq '/faq', :controller => 'home', :action => 'faq'
  map.faq '/tour', :controller => 'home', :action => 'tour'
  map.faq '/bookkeeper', :controller => 'home', :action => 'bookkeeper'
  map.first_profile_edit "/profiles/newedit", :controller => 'profiles',  :action => 'new_edit'    
  map.profiles '/profiles', :controller => 'profiles', :action => 'edit'  
  map.professionals '/professionals', :controller => 'rac_contest', :action => 'index'
  map.tell_a_client '/tell_a_client', :controller => 'rac_contest', :action => 'tell_a_client'
  map.admin '/admin', :controller => 'admin/overview', :action => 'index'

  map.connect '/activate/:activation_code', :controller => 'users', :action => 'activate'
  
	map.login  '/login', :controller => 'session', :action => 'new'
	map.logout '/logout', :controller => 'session', :action => 'destroy', :method => :delete
	map.caslogout '/caslogout', :controller => 'session', :action => 'destroy', :method => :delete
  
  map.access_denied 'access/denied', :controller => 'access', :action => 'denied'
  map.access '/access/:access', :controller => 'access', :action => 'access'  

  map.toggle_access '/access/toggle/:id', :controller => 'access', :action => 'toggle_access'

  # became online_payments/:gateway/show
# map.direct_payment '/payments/:gateway/:access/direct', :controller => 'online_payments', :action => 'direct'
  # became online_paymens/confirm
# map.direct_payment_confirm '/payments/:access/confirm', :controller => 'online_payments', :action => 'confirm'
  # became online_payments/complete
# map.direct_payment_complete '/payments/:access/complete', :controller => 'online_payments', :action => 'complete'
  # became online_payments/cancel
# map.direct_payment_cancel '/invoices/:invoice_id/online_payments/cancel', :controller => 'online_payments', :action => 'cancel'
  # became online_payments [post] #create
# map.submit_payment '/invoices/:invoice_id/online_payments/submit', :controller => 'online_payments', :action => 'submit'
  
  
  map.global_rescue '/global_rescue', :controller => 'global_rescue', :action => 'index'
  map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'
  
  map.invite_a_friend '/invite_a_friend', :controller => 'referral', :action => 'new'
  map.invite_a_friend '/simplyaccounting/recommend', :controller => 'referral', :action => 'new'

  map.tabs '/tabs/:action', :controller => 'tabs'
  map.connect '/:controller/:action/:id'
  map.connect '/:controller/:action/:id.:format'
  map.api_default '/api/simply/:controller/:action/:id'
  map.api_default_formatted '/api/simply/:controller/:action/:id.:format'

  map.home '/', :controller => 'home', :action => 'index'
  
  
  map.delete_bookkeeper_contract '/bookkeepers/delete_contract/:id', :controller => 'bookkeeper', :action => 'delete_contract'
  map.withdraw_bookkeeper_invitation '/bookkeepers/withdraw_invitation/:id', :controller => 'bookkeeper', :action => 'withdraw_invitation'
  

  if %w{test}.include?(ENV['RAILS_ENV'])        
    map.mock_cas 'mock/cas', :controller => 'mock_cas', :action => 'cas'
    map.current_session 'current_session', :controller => 'session', :action => 'current_session'
  end
  
    
end
