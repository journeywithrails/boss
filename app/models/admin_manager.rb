class AdminManager
  class << self
      def admin_users
        users = User.find(:all, :include=>:roles, :conditions=>["roles.id= (?)", Role.find_by_name('admin')])
        return users
      end

      def admin_roles(chomp=false)
        roles = Role.find(:all)
        u_roles = []
        roles.each do |a|
          if a.name.match(/_admin$/) and (a.name.match(/_admin$/)[0] == "_admin")
            name = a.name
            if chomp
              name = name.chomp('_admin')
            end
            u_roles << name
          end
        end
        return u_roles    
      end

      def user_count( currency = nil )
        if currency.nil?
          User.count( :all, :conditions => ["bogus = 0"])
        else
          User.count( 'users.id', :distinct => true, :joins => "left outer join invoices on invoices.created_by_id = users.id", :conditions => ["bogus = 0 and invoices.currency = ?", currency])
        end
      end

      def invoice_mean( currency = nil )
        if currency.nil?
          prettify_result( Invoice.average('total_amount', :joins => "left outer join users on invoices.created_by_id = users.id", :conditions => ["users.bogus = 0"]))
        else
          prettify_result( Invoice.average('total_amount', :joins => "left outer join users on invoices.created_by_id = users.id", :conditions => ["users.bogus = 0 and currency = ?", currency]))
        end
      end

      def payment_mean( currency = nil )
        if currency.nil?
          prettify_result( Invoice.average('paid_amount', :joins => "left outer join users on invoices.created_by_id = users.id", :conditions => ["users.bogus = 0 and status = 'paid'"]))
        else
          prettify_result( Invoice.average('paid_amount', :joins => "left outer join users on invoices.created_by_id = users.id", :conditions => ["users.bogus = 0 and status = 'paid' and currency = ?", currency]))
        end
      end

      def invoice_count( currency = nil )
        if currency.nil?
          Invoice.count( :all, :conditions => ["users.bogus = 0"], :joins => "left outer join users on invoices.created_by_id = users.id")
        else
          Invoice.count( :all, :conditions => ["users.bogus = 0 and currency = ?", currency], :joins => "left outer join users on invoices.created_by_id = users.id")
        end
      end

      def simply_invoice_count
        Invoice.count( :all, :conditions => ["users.bogus = 0 and invoices.simply_guid is not null"], :joins => "left outer join users on invoices.created_by_id = users.id")
      end

      def payment_count( currency = nil )
        if currency.nil?
          Invoice.count( :all, :conditions => ["users.bogus = 0 and status = 'paid'"], :joins => "left outer join users on invoices.created_by_id = users.id")
        else
          Invoice.count( :all, :conditions => ["users.bogus = 0 and status = 'paid' and currency = ?", currency], :joins => "left outer join users on invoices.created_by_id = users.id")
        end
      end

      def invoice_sum( currency = nil )
        result = 0;
        if currency.nil?
          prettify_result( Invoice.sum( :total_amount, :conditions => ["users.bogus = 0"], :joins => "left outer join users on invoices.created_by_id = users.id"))
        else
          prettify_result( Invoice.sum( :total_amount, :conditions => ["users.bogus = 0 and currency = ?", currency], :joins => "left outer join users on invoices.created_by_id = users.id"))
        end
      end

      def payment_sum( currency = nil )
        if currency.nil?
          prettify_result( Invoice.sum( :paid_amount, :conditions => ["users.bogus = 0 and status = 'paid'"], :joins => "left outer join users on invoices.created_by_id = users.id"))
        else
          prettify_result( Invoice.sum( :paid_amount, :conditions => ["users.bogus = 0 and status = 'paid' and currency = ?", currency], :joins => "left outer join users on invoices.created_by_id = users.id"))
        end
      end

      def simply_sending_users
        User.count( :all, :conditions => ["bogus = 0 and id in (select distinct created_by_id from invoices where simply_guid is not null)"])
      end

      def gateway_users( gateway_name )
        UserGateway.count( :all, :joins => "left outer join users on user_gateways.user_id = users.id", :conditions => ["user_gateways.type = ? and users.bogus = 0", gateway_name ] )
      end

      def payment_gateway_users
        array_from_sql("select users.id, users.sage_username, user_gateways.type, users.created_at
                       from user_gateways
                         left outer join users
                           on user_gateways.user_id = users.id
                       where users.bogus = 0
                       group by user_gateways.type, sage_username, id
                       order by user_gateways.type, sage_username")
      end

      def users_who_joined_after_being_invoiced
        array_from_sql("select distinct users.sage_username as invitee, users.id as invitee_id, users2.sage_username as inviter, users2.id as inviter_id from users left outer join deliveries on users.email like deliveries.recipients left outer join users as users2 on users2.id = deliveries.created_by_id where users.id <> deliveries.created_by_id and users.created_at > deliveries.created_at and users.bogus = 0 and deliverable_type = 'Invoice' and users2.sage_username <> users.sage_username and users2.bogus = 0")
      end

      def users_sharing_data
        array_from_sql("select u1.login as inviter_login, u1.id as inviter_id, u2.login as invitee_login, u2.id as invitee_id from bookkeeping_contracts left outer join bookkeepers on bookkeeping_contracts.bookkeeper_id = bookkeepers.id left outer join invitations on bookkeeping_contracts.invitation_id = invitations.id left outer join users u1 on invitations.created_by_id = u1.id left outer join users u2 on invitations.invitee_id = u2.id where u1.bogus = 0 and u2.bogus = 0")
      end

      def invoiced_currencies
        array_from_sql("SELECT DISTINCT(currency) from invoices left outer join users on invoices.created_by_id = users.id where currency is not null and users.bogus = 0 GROUP BY currency ORDER BY COUNT(currency) DESC")
      end

      def invoices_by_date
        array_from_sql("select date(invoices.created_at), count(invoices.created_at) from invoices left outer join users on users.id = invoices.created_by_id where users.bogus <> '1' group by date(invoices.created_at)")
      end

      def invoices_by_currency
        array_from_sql("(SELECT DISTINCT(currency) as currency, count(*) as invoice_count, count(distinct invoices.created_by_id) as unique_users, avg(invoices.total_amount) as average_amount, sum(invoices.total_amount) as total_amount, avg(invoices.paid_amount) as average_paid, sum(invoices.paid_amount) as total_paid, avg(invoices.owing_amount) as average_owing, sum(invoices.owing_amount) as total_owing 
                           from invoices left outer join users on invoices.created_by_id = users.id 
                           where currency is not null and users.bogus = 0 GROUP BY currency)
                        UNION ALL
                        (SELECT '-- all --', count(*) as invoice_count, count(distinct invoices.created_by_id) as unique_users, avg(invoices.total_amount) as average_amount, sum(invoices.total_amount) as total_amount, avg(invoices.paid_amount) as average_paid, sum(invoices.paid_amount) as total_paid, avg(invoices.owing_amount) as average_owing, sum(invoices.owing_amount) as total_owing 
                           from invoices 
                           left outer join users on invoices.created_by_id = users.id 
                           where users.bogus = 0) 
                        ORDER BY invoice_count DESC")
      end

      def customers_by_language
        array_from_sql("select distinct customers.language, count(customers.language) as customers 
                          from customers
               left outer join users on users.id = customers.created_by_id
                         where customers.language is not null and customers.language is not null and users.bogus = 0
                      group by language
                      order by customers DESC, language ASC")
      end

      def customers_by_country
        array_from_sql("select distinct customers.country, count(customers.country) as customers 
                          from customers
               left outer join users on users.id = customers.created_by_id
                         where users.bogus = 0
                      group by customers.country
                      order by customers DESC, country ASC")
      end

      def users_by_language
        array_from_sql("select distinct language, count(language) as user_count
                          from users
                         where language is not null and bogus = 0
                      group by language
                      order by user_count DESC, language ASC")
      end

      def users_by_country
        array_from_sql("select distinct replace(replace(configurable_settings.value,'--- ',''),'\n','') as country, 
                               count(configurable_settings.value) as user_count
                          from users 
               left outer join configurable_settings on users.id = configurable_settings.configurable_id and configurable_type='User' and name='company_country'
                         where users.bogus = 0
                      group by configurable_settings.value
                      order by user_count DESC, country ASC")
      end

      def users_by_customers
        array_from_sql("select users.id, users.sage_username, count(customers.id), users.created_at from customers left outer join users on customers.created_by_id = users.id where users.bogus = 0 group by created_by_id order by count(customers.id) desc, users.created_at asc")
      end

      def referral_summary
        array_from_sql("select count(referring_email) as referral_count, referring_email from referrals left outer join users on users.sage_username = referrals.referring_email where users.bogus = 0 group by referring_email order by count(referring_email) desc")
      end

      # How the users say they found out about Billing Boss
      def user_referral_sources
        array_from_sql("select count(cfs1.value) as heard_from_count,
                          replace(replace(cfs1.value,'--- ',''),'\n','') as heard_from,
                          replace(replace(cfs2.value,'--- ',''),'\n','') as heard_from_specific
                        from configurable_settings as cfs1
                          left outer join configurable_settings as cfs2
                            on cfs1.configurable_id = cfs2.configurable_id
                              and cfs1.configurable_type = cfs2.configurable_type
                              and cfs2.name = 'heard_from_specific'
                          left outer join users on cfs1.configurable_id = users.id
                        where cfs1.name = 'heard_from' and users.bogus <> '1'
                        group by cfs1.value, cfs2.value
                        order by cfs1.value, cfs2.value")
      end

      def users_summary
        array_from_sql("select users.id, count(invoices.created_by_id) as count, signup_type, 
                               users.created_at as signup_date, max(invoices.updated_at) as
                               last_invoice_update, replace(replace(c.value,'--- ',''),'\n','') as
                               mail_opt_in
          from users left outer join invoices on users.id = invoices.created_by_id
          left outer join configurable_settings c on c.configurable_id = users.id and (c.name is null or c.name = 'mail_opt_in')
          where bogus = 0
          group by email order by count(invoices.created_by_id) desc, last_invoice_update asc, signup_date asc")
      end

      def users_details
        array_from_sql("select users.id, count(invoices.created_by_id) as count, email, sage_username, signup_type,
                               language, replace(replace(d.value,'--- ',''),'\n','') as country,
                               users.created_at as signup_date, max(invoices.updated_at) as
                               last_invoice_update, replace(replace(c.value,'--- ',''),'\n','') as
                               mail_opt_in, bogus
          from users left outer join invoices on users.id = invoices.created_by_id
          left outer join configurable_settings c on c.configurable_id = users.id and (c.name is null or c.name = 'mail_opt_in')
          left outer join configurable_settings d on users.id = d.configurable_id and d.configurable_type='User' and d.name='company_country'
          group by email order by count(invoices.created_by_id) desc, last_invoice_update asc, signup_date asc")
      end

      def admin_roles_for(user, chomp=false, specific=false)
        if user.has_role?("master_admin") && !specific
          roles = Role.find(:all)
        else
          roles = user.roles
        end
        a_roles = []
        roles.each do |a|
          if a.name.match(/_admin$/) and (a.name.match(/_admin$/)[0] == "_admin")
            name = a.name
            if chomp
              name = name.chomp('_admin')
            end
            a_roles << name
          end
        end
        return a_roles
      end

      def add_admin_role_to_user(user, role)
        return if user.has_role?(role)
        if self.admin_roles.include?(role)
          if !user.has_role?('admin')
            self.create_generic_admin(user)
          end
          user.has_role(role)
          user.save
        else
            raise Sage::BusinessLogic::Exception::RolesException, "Can't add admin role '#{role}' to user '#{user.sage_username}': Admin role does not exist"
        end
      end

      #hook means that if the removed role was the last non-generic
      #admin role the user had, the generic role will be removed as well
      #is is NOT related to the "hook" hack I added to has_no_role method
      def remove_admin_role_from_user(user, role, hook=false)
        return unless user.has_role?(role)
        if self.admin_roles.include?(role)
          user.has_no_role(role, nil, false)
          if hook and user.has_role?("admin")
            user_roles = self.admin_roles_for(user, false)
            if (user_roles.size == 0)
              self.delete_generic_admin(user)
            end
          end
        else
            raise Sage::BusinessLogic::Exception::RolesException, "Can't remove admin role '#{role}' from user '#{user.sage_username}': Admin role does not exist"
        end  
      end

      def create_generic_admin(user)
        return if user.has_role?("admin")
        user.has_role("admin")
        user.save
      end

      #warning, below function will strip user of ALL admin roles
      #before removing the generic admin
      def delete_generic_admin(user)
        admin_roles = self.admin_roles_for(user)
          admin_roles.each do |r|
            self.remove_admin_role_from_user(user, r, false)
          end
        return unless user.has_role?("admin")
        user.has_no_role("admin", nil, false)
        user.save
      end

      def commify_result( value )
        value = prettify_result( value )
        value.to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
      end

    private
      def prettify_result( value )
        result = value
        result = 0 if result.blank?
        result.floor.to_i
      end

      def array_from_sql( stmt )
        ActiveRecord::Base.connection.execute( stmt ).extend(Enumerable).to_a
      end
  end
end
