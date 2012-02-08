module RacContestHelper
  def rac_contest_menu_builder
    menu_link = ["index", "enter", "tell_a_client", "tour", "rules"]
    menu = ""
    menu_link.each_with_index do |menu_item, i|
      if @contest_action == menu_item
        menu += "<li class='link#{i+1}_current'><img border='0' alt='#{menu_item.humanize}' src='/images/rac_contest/spacer.gif'/></li>"        
      else
        menu += "<li class='link#{i+1}'><a href='/rac_contest/#{menu_item}'><img border='0' alt='#{menu_item.humanize}' src='/images/rac_contest/spacer.gif'/></a></li>"
      end
    end
    menu
  end
end
