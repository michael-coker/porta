# frozen_string_literal: true

# TODO: Rails 5 --> class DeleteServiceStatsWorker < ApplicationJob
class DeleteServiceStatsWorker < ActiveJob::Base
  def perform(service)
    @service = service

    batch = Sidekiq::Batch.new
    batch.description = "Delete Backend Stats for service ##{service.id}"
    batch.jobs do
      build_jobs_existing_metrics
      build_jobs_deleted_metrics
    end
  end

  private

  attr_reader :service

  def build_jobs_existing_metrics
    service.metrics.select(:id).find_each do |metric|
      puts "The ThreeScale::Core and Backend part doesn't exist yet to destroy the metric ##{metric.id}"
      ::DeleteServiceStatsWorkerTest::FakeStubBackendDeleteStat.new(metric)
    end
  end

  def build_jobs_deleted_metrics
    service.deleted_metrics.find_each do |deleted_metric|
      metric = deleted_metric.object_instance(attributes: [:created_at])
      puts "The ThreeScale::Core and Backend part doesn't exist yet to destroy the metric ##{metric.id}"
      ::DeleteServiceStatsWorkerTest::FakeStubBackendDeleteStat.new(metric)
    end
  end

  # TODO: do the same with applications as done with metrics
end
