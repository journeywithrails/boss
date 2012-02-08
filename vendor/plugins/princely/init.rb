Mime::Type.register 'application/pdf', :pdf

ActionController::Base.send(:include, Princely::PdfHelper)