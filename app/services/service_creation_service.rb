# frozen_string_literal: true

class ServiceCreationService
  def initialize(provider_account, service_params = {})
    @provider_account = provider_account
    @service_params = service_params
  end

  attr_reader :provider_account, :service_params, :success, :service

  def self.call(*args)
    object = new(*args)
    object.call
    object
  end

  def call
    @service = if service_params[:source] == 'discover'
                 create_service_async
               else
                 create_service
               end
  end

  def create_service
    service = build_service service_params.slice(:name, :system_name, :description)
    @success = service.save
    service
  end

  def create_service_async
    ServiceDiscovery::ImportClusterServiceDefinitionsWorker.perform_async(provider_account.id, *service_params.values_at(:namespace, :name))
    @success = true
    build_service service_params.slice(:name)
  end

  def success?
    !!success
  end

  def build_service(service_params = {})
    provider_account.accessible_services.build service_params
  end
end
