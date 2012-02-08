class TestData
  require 'babel'
  
  def really_big_invoice
    u = User.find_by_sage_username('basic_user' )
    i=u.invoices.create(
      :customer => u.customers.first,
      :description => Babel.random_long
    )
    
    150.times do
      i.line_items.create(
        :quantity => rand(10),
        :price => "#{rand(100)}.#{rand(100)}",
        :description => Babel.random_short.gsub( '&', 'and' ),
        :name => Babel.random_short.gsub( '&', 'and' )
      )
    end
    
    i
  end
end

$t=TestData.new
