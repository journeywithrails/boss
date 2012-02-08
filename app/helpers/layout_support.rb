module LayoutSupport
  def self.included(base)
    base.send :helper_method, :active_layout, :print?, :print!, :controller_name_for_theme
    base.send :before_filter, :collect_layout_params
  end

  protected

  def collect_layout_params
    p = params.delete(:_print)
    @print = !!p unless p.nil?

    p = params.delete(:_show_lnav)
    @show_lnav = !!p unless p.nil?    
  end
     
  def print?
    @print = false unless instance_variable_defined? :@print
    @print
  end
  def print_on!; @print = true; end
  def print_off!; @print = false; end

  def controller_name_for_theme
    @controller_name_for_theme || self.controller_name
  end

  def controller_name_for_theme=(name)
    @controller_name_for_theme = name
  end

  def default_layout(force_external=false)
    if logged_in? && !force_external
      'main'
    else
      'external_main'
    end
  end

  def internal_layout
    raise Sage::BusinessLogic::Exception::AccessDeniedException unless logged_in? 
    'main'
  end

  def render_with_a_layout(action, layout=nil)
    render :action => "#{action}_#{!layout.nil? ? layout : default_layout}", :layout => (!layout.nil? ? layout : default_layout)        
  end
  
  def internal_or_external_layout(force_external=false)
    return @custom_layout if @custom_layout
    default_layout(force_external)
  end

  def external_layout
    internal_or_external_layout(true)
  end

  def biller_view
    current_user.current_view = :biller unless !logged_in?
  end
  
  def bookkeeper_view
    current_user.current_view = :bookkeeper unless !logged_in?
  end

  def admin_view
    current_user.current_view = :admin unless !logged_in?
  end
  
end