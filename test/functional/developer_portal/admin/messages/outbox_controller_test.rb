require 'test_helper'

class DeveloperPortal::Admin::Messages::OutboxControllerTest < DeveloperPortal::ActionController::TestCase
  with_options :controller => 'messages/outbox' do |test|
    test.should route(:get, '/admin/messages/sent').to :action => 'index'
    test.should route(:get, '/admin/messages/new').to :action => 'new'
    test.should route(:post, '/admin/messages/sent').to :action => 'create'
    test.should route(:get, '/admin/messages/sent/42').to :action => 'show', :id => '42'
    test.should route(:delete, '/admin/messages/sent/42').to :action => 'destroy', :id => '42'
  end

  test "creates messages with origin == 'web'" do
    @provider = Factory :provider_account
    @buyer = Factory :buyer_account, :provider_account => @provider
    @request.host = @provider.domain
    login_as(@provider.admins.first)

    post :create, :message => { :subject => "message via web", :body => "message via web" }, :to => @buyer.id
    MessageWorker.drain
    assert msg = Message.last
    assert_equal "web", msg.origin
  end
end
