# frozen_string_literal: true

# TODO: Rails 5 --> class DeleteProviderStatsWorker < ApplicationJob
class DeleteProviderStatsWorker < ActiveJob::Base
  def perform(provider)
    @provider = provider

    batch = Sidekiq::Batch.new
    batch.description = "Delete Backend Stats for provider ##{provider.id}"
    batch.jobs do
      build_jobs_existing_services
      build_jobs_deleted_services
    end
  end

  private

  attr_reader :provider

  def build_jobs_existing_services
    provider.services.select(:id).find_each do |service|
      DeleteServiceStatsWorker.perform_later service
    end
  end

  def build_jobs_deleted_services
    provider.deleted_services.find_each do |deleted_service|
      DeleteServiceStatsWorker.perform_later deleted_service.missing_model_instance
    end
  end
end
