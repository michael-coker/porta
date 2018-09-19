# frozen_string_literal: true

require 'test_helper'

class DeleteServiceStatsWorkerTest < ActiveSupport::TestCase
  setup do
    @service = FactoryGirl.create(:service)
    FactoryGirl.create_list(:metric, 2, service: service)
    service.metrics.where.has { system_name != 'hits' }.destroy_all
    assert_equal 1, service.metrics.count
    assert_equal 2, service.deleted_metrics.count
    @worker = DeleteServiceStatsWorker.new
  end

  attr_reader :service, :worker

  test '#perform calls DeleteServiceStatsWorker for all existing metrics' do
    worker.stubs(:build_jobs_deleted_metrics)

    FakeStubBackendDeleteStat.expects(:new).times(1).with(instance_of(Metric))
    worker.perform(service)
  end

  test '#perform calls DeleteServiceStatsWorker for all deleted metrics' do
    worker.stubs(:build_jobs_existing_metrics)

    FakeStubBackendDeleteStat.expects(:new).times(2).with(instance_of(Metric))
    worker.perform(service)
  end

  test '#perform calls DeleteServiceStatsWorker for all existing applications' do
    skip 'TODO - WIP'
  end

  test '#perform calls DeleteServiceStatsWorker for all deleted applications' do
    skip 'TODO - WIP'
  end

  class FakeStubBackendDeleteStat
    def initialize(_metric); end
  end
end
