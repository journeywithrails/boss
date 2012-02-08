class Admin::OverviewController < ApplicationController

  prepend_before_filter CASClient::Frameworks::Rails::Filter  
  permit "admin"
  
    def index

    end

    def details
      
    end

    def user
      @user = User.find(params[:id]) unless params[:id].blank?
      respond_to do |format|
        format.html # user.html.erb
      end
    end

    def users_details
      standard_responder(["ID", "Invoices", "Email", "Username", "Type", "Language", "Country", "Signup", "Last_Invoice", "Mail_opt-in", "Bogus"], AdminManager.users_details)
    end

    def users_summary
      standard_responder(["ID", "Invoices", "Type", "Signup", "Last_Invoice", "Mail_opt-in"], AdminManager.users_summary)
    end

    def users_by_country
      standard_responder(["country", "users", "invoices", "paid_invoices", "average_customers"], AdminManager.users_summary)
    end

    def toggle_bogus_user
      u = User.find(params[:id])
      u.bogus = !u.bogus
      if u.save
        render :text => u.bogus ? "true" : "false"
      else
        render :text => "error"
      end
    end

    def referral_summary
      standard_responder(["Count", "Email"], AdminManager.referral_summary)
    end

    def user_referral_sources
      standard_responder(["Count", "Source", "Details"], AdminManager.user_referral_sources)
    end

    def payment_gateway_users
      standard_responder(["UserID", "UserEmail", "PaymentGateway", "UserCreatedAt"], AdminManager.payment_gateway_users)
    end

    def invoices_by_currency
      standard_responder(["Currency", "NumberOfUsers", "NumberOfInvoices", "NumberPaid",
                "AverageAmount", "TotalAmount", "AveragePayment", "TotalPayments"], AdminManager.invoices_by_currency)
    end

    def invoices_by_date
      standard_responder(["Date", "NumberOfInvoices"], AdminManager.invoices_by_date)
    end

    def customers_by_language
      standard_responder(["language", "number_of_customers"], AdminManager.customers_by_language)
    end

    def customers_by_country
      standard_responder(["country", "number_of_customers"], AdminManager.customers_by_country)
    end

    def users_by_language
      standard_responder(["language", "number_of_users"], AdminManager.users_by_language)
    end

    def users_by_country
      standard_responder(["country", "number_of_users"], AdminManager.users_by_country)
    end

    def users_by_customers
      standard_responder(["user_id", "user_email", "number_of_customers", "user_signup_date"], AdminManager.users_by_customers )
    end

    def users_who_joined_after_being_invoiced
      standard_responder(["invitee_user_login", "invitee_user_id", "inviter_user_login", "inviter_user_id"], AdminManager.users_who_joined_after_being_invoiced )
    end

    def users_sharing_data
      standard_responder(["inviter_user_login", "inviter_id", "invitee_user_login", "invitee_id"], AdminManager.users_sharing_data )
    end

  protected
    def standard_responder(headers, collect)
      respond_to do |format|
        format.html
        format.csv do
          stream_csv do |csv|
            csv << headers
            collect.each do |r|
              csv << r
            end
          end
        end
      end
    end

  end
