module ContestHelper
  def contest_menu_builder
    menu_link = ["index", "tell_a_friend", "tour", "winners", "rules"]
    menu = ""
    menu_link.each_with_index do |menu_item, i|
      if @contest_action == menu_item
        menu += "<li class='link#{i+1}_current'><img border='0' alt='#{menu_item.humanize}' src='/images/contest/spacer.gif'/></li>"        
      else
        menu += "<li class='link#{i+1}'><a href='/contest/#{menu_item}'><img border='0' alt='#{menu_item.humanize}' src='/images/contest/spacer.gif'/></a></li>"
      end
    end
    menu
  end
  
  def contest_create_account_link
    link_to_signup image_tag('/images/contest/btn_signup.gif'), :service_url => profiles_url
  end

end
