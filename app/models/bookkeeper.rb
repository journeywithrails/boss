class Bookkeeper < ActiveRecord::Base
  has_one  :user, :dependent => :nullify
  
  has_many :bookkeeping_contracts
  has_many :bookkeeping_clients, :class_name => 'Biller', :through => :bookkeeping_contracts
  
  include CountrySettings  
  
  def keep_books_for!(biller, invitation=nil)
    if self.bookkeeping_contracts.find_by_bookkeeping_client_id(biller).nil?
      if not self.bookkeeping_contracts.create(:bookkeeping_client => biller, :invitation => invitation)
        raise Sage::BusinessLogic::Exception::BookkeepingContractException, "Could not create bookkeeping_contract for bookkeeper #{self.id}"
      end
    end
    if not self.user.has_role?('bookkeeping', biller.user)
      if not self.user.has_role('bookkeeping', biller.user)
        raise Sage::BusinessLogic::Exception::RolesException, "Could not add role 'bookkeeping' to bookkeeper #{self.id} on biller #{biller.id}"
      end
    end
    self.user.current_view = :biller 
    #TODO: notify biller
    true
  end
  
#  def keeps_books_for?(biller)
#    (not self.bookkeeping_contracts.find_by_bookkeeping_client_id(biller).nil?) and
#      self.user.has_role?('bookkeeping', biller.user)
#  end
  
  def stop_keeping_books_for!(biller)
    if not self.user.has_no_role('bookkeeping', biller.user)
      raise Sage::BusinessLogic::Exception::RolesException, "Could not remove role 'bookkeeping' to bookkeeper #{self.id} on biller #{biller.id}"
    end
    bkc = self.bookkeeping_contracts.find_by_bookkeeping_client_id(biller)
    if not bkc.nil?
      bkc.destroy
    else
      raise Sage::BusinessLogic::Exception::BookkeepingContractException, "Could not find contract for bookkeeper #{self.id} on biller #{biller.id}"
    end
    
    #TODO: notify biller
    true
  end

  def method_missing(symbol, *params)
    RAILS_DEFAULT_LOGGER.warn "biller #{id} delegating #{symbol.to_s} to user"
    self.user.send(symbol, *params)
  end
  
end