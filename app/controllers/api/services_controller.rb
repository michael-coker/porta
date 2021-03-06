class Api::ServicesController < Api::BaseController
  activate_menu :serviceadmin, :overview

  before_action :deny_on_premises_for_master
  before_action :authorize_manage_plans, only: %i[create destroy]
  before_action :authorize_admin_plans, except: %i[create destroy]

  load_and_authorize_resource :service, through: :current_user,
    through_association: :accessible_services, except: [:create]

  with_options only: [:edit, :update, :settings, :notifications] do |actions|
    actions.sublayout 'api/service'

    #actions.before_action :activate_submenu
  end

  def index
    @services = ::ServiceDecorator.decorate_collection(@services)
  end

  def show
  end

  def new
    @service = collection.build params[:service]
  end

  def edit
    activate_menu :serviceadmin, :api, :definition
  end

  def settings
  end

  def notifications
    @alert_limits = Alert::ALERT_LEVELS
    activate_menu :sidebar => :alerts
  end

  def create
    @service = collection.new # this is done in 2 steps so that the account_id is in place as preffix_key relies on it
    @service.attributes = params[:service]
    @service.system_name = params[:service][:system_name]

    if can_create? && @service.save
      flash[:notice] =  'Service created.'
      onboarding.bubble_update('api')
      redirect_to admin_services_path(anchor: "service_#{@service.id}")
    else
      flash.now[:error] = "Couldn't create service. Check your Plan limits"
      render :new
    end
  end

  def update
    if @service.update_attributes(params[:service])
      flash[:notice] =  'Service information updated.'
      onboarding.bubble_update('api') if service_name_changed?
      onboarding.bubble_update('deployment') if integration_method_changed? && !integration_method_self_managed?
      redirect_back_or_to :action => :settings
    else
      render :action => :edit # edit page is only page with free form fields. other forms are less probable to have errors
    end
  end

  def destroy
    @service.mark_as_deleted!
    flash[:notice] = "Service '#{@service.name}' will be deleted shortly. You will receive a notification when it is done"
    redirect_to admin_services_path
  end

  protected

  def service_name_changed?
    @service.previous_changes['name']
  end

  def integration_method_changed?
    @service.previous_changes['deployment_option']
  end

  def integration_method_self_managed?
    @service.proxy.self_managed?
  end

  def collection
    current_user.accessible_services
  end

  def can_create?
    can? :create, Service
  end

  def authorize_manage_plans
    authorize! :manage, :plans
  end

  def authorize_admin_plans
    authorize! :admin, :plans
  end
end
