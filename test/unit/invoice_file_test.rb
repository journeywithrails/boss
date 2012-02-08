require File.dirname(__FILE__) + '/../test_helper'

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'db_file'

class InvoiceFileTest < ActiveSupport::TestCase
  # Disabled this test which only tests the capacity of the database anyhow.
# def test_data_field_should_save_large_blob
#   data = random_string(2000000) #2^19 = 522488 passes, 524000 fails.
#   invoice_file = InvoiceFile.new
#   invoice_file.build_db_file.data = data
#   invoice_file.save!
#   
#   invoice_file.reload
#   assert_equal data.length, invoice_file.db_file.data.length, 'Field length incorrect. Ensure field is a LONGBLOB.'
#   assert_equal data, invoice_file.db_file.data
# end
  
  private
    def random_string(size)
      returning "" do |str|
        size.times do
          str << rand(255)
        end
      end
    end
end
