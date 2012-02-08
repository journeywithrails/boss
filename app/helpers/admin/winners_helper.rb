module Admin
  module WinnersHelper
    def add_winner_link(name, *properties)
    
      out = link_to_function name, *properties do |page|
        page.insert_html :before, 'add_winner_row', :partial => '/admin/winners/form_one'

      end
      out
    end

  end
end