class Logo < ActiveRecord::Base
  has_attachment :content_type => :image,
                 :storage => ::AppConfig.attachment_storage,
                 :processor => 'Rmagick',
                 :max_size => ::AppConfig.invoice.logo.max_size,
                 :resize_to => ::AppConfig.invoice.logo.dimensions,
                 :thumbnails => { :thumb => '50x50>' }
  
    
  belongs_to :created_by, :class_name => 'User', :foreign_key => :created_by_id

  validates_attachment  :content_type => _("The file you uploaded was not a JPEG, PNG or GIF"),
                        :size         => _("The image you uploaded was larger than the maximum size of %{size}") % {:size => ::AppConfig.invoice.logo.max_size }
                        
  
end

