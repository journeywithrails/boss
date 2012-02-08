module UserGatewaysHelper
  def gateway_selection(gateway, user_gateway)
    checkbox = check_box_tag('user_gateway_selections[]', gateway.gateway_name, user_gateway, 
                             :onclick => "Sage.displayOnlinePayment('#{ gateway.gateway_name }', this.checked)")
    %{<label>#{ checkbox } #{ gateway.selection_text }</label><div class='gateway_tease'> – #{ gateway.tease_text }</div>}
  end

  def user_gateway_div(gateway, user_gateway)
    open_div = %{<div id="#{ gateway.gateway_name }_form" class="user_gateway_setup">}
    if user_gateway
      <<-html
      #{ open_div }
        #{ render(:partial => user_gateway.form_partial, :locals => { :user_gateway => user_gateway }) }
      </div>
      html
    else
      "#{ open_div }</div>"
    end
  end

  def render_gateway(gateway, user_gateways)
    user_gateways ||= []
    user_gateway = user_gateways.detect { |ug| ug.supports?(gateway) }
    <<-html
    <div class="gateway_selection">
      #{ gateway_selection(gateway, user_gateway) }
      #{ user_gateway_div(gateway, user_gateway) }
    </div>
    html
  end
  
  def loading_string
    "#{_('Loading...')} #{ localized_image_tag('/images/loading.gif') }"
  end
end
