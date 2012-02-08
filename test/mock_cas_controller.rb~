class MockCasController  < ActionController::Base
  def cas
    if request.post?
    else
      render :template => "/test/cas/login"
    end
  end
end
