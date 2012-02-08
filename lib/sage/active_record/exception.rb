#TODO: discuss & determine best way of organizing exceptions
module Sage
  module ActiveRecord
    module Exception
      # indicates conditions on an association were violated
      class ConditionsViolatedException < StandardError; end
      
      # indicates a child entity was asked for that did not belong to the parent entity
      class OutOfScope < StandardError; end
    end
  end
end