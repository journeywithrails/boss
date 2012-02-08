class ActionController::Base
  # Make private aliases of the filter methods we need so that I can
  # add filters in this module without worrying about affecting them in
  # the controller or having to redefine all of the :only and :except 
  # arguments.
  #
  # The options argument is required to remind me that the filter is still
  # working in the scope of the controller this is being included in and
  # would apply to all actions by default just like if it was defined 
  # right in the target controller as normal.
  def self.module_before_filter(alias_name, method, options)
    alias_method :"#{ method }_#{ alias_name.underscore }", method
    before_filter :"#{ method }_#{ alias_name.underscore }", options
  rescue => e
    warn "WARNING: filter method being used by module_before_filter must be defined."
    warn "         module_before_filter(#{ alias_name.inspect }, #{ method.inspect }, #{ options.inspect })"
    warn "         This may cause unrelated classes not to load correctly."
    raise
  end
end

