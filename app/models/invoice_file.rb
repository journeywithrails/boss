require 'db_file' # we need this so that weenie doesn't pre-emptively create an anonymous dbfile class

class InvoiceFile < ActiveRecord::Base
  has_attachment :content_type => 'application/pdf', 
                 :storage => :db_file,
                 :processor => 'Rmagick', 
                 :max_size => 5.megabytes
                 
  belongs_to    :invoice

end