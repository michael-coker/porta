class Provider::Admin::CMS::BaseController < FrontendController

  activate_menu :cms
  sublayout :cms

  before_action :authorize_portal

  protected

  def authorize_portal
    authorize! :manage, :portal
  end

end
