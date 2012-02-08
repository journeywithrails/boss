#TODO: discuss & determine best way of organizing exceptions
module Sage
  module BusinessLogic
    module Exception
      # indicates an invoice was saved with a contact with no customer
      class OrphanedContactException < StandardError; end
      class UnknownDiscountTypeException < StandardError; end
      class MalformedPaymentException < StandardError; end
      class CantPerformEventException < StandardError
        def initialize(record, event)
          super "#{record.class.name}(#{record.id}) can't #{event.to_s} when #{record.status}"
        end
      end
      class PaymentInProgressException < StandardError; end
      class BillingError < StandardError; end
      class Error < StandardError; end
      class RolesException < StandardError; end
      class BookkeepingContractException < StandardError; end
      
      class TypeError < StandardError; end
      class MissingTypeException < TypeError; end
      class WrongTypeException < TypeError; end
      
      class IncompleteClassException < StandardError; end
      
      class MissingDataException < StandardError; end
      class IncorrectDataException < StandardError; end
      class IncompatibleDataException < StandardError; end 
      
      class ConcurrencyException < StandardError; end 
      
      class AccessDeniedException < StandardError; end
      class InvalidCaptchaException < StandardError; end
    end
  end
end