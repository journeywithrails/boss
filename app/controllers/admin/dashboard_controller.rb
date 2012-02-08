class Admin::DashboardController < ApplicationController
  if %w{test development}.include?(ENV['RAILS_ENV'])
    def recalc
      Invoice.find(:all).each{|i| i.save(false)}
      render :text => '1'
    end

    def show_urls
      @url_for_named_route = url_for(invoices_url)
      @url_for_string = url_for("invoices/1/edit")
  		@url_for_absolute_string = url_for("/invoices/1/edit")
      
      render :partial => 'urls'
    end
  end
end