# frozen_string_literal: true

require 'test_helper'

class DeleteProviderStatsWorkerTest < ActiveSupport::TestCase
  setup do
    @provider = FactoryGirl.create(:simple_provider)
    FactoryGirl.create_list(:service, 4, account: provider)
    provider.services.order(created_at: :desc).limit(2).destroy_all
    assert_equal 2, provider.services.count
    assert_equal 2, provider.deleted_services.count
    @worker = DeleteProviderStatsWorker.new
  end

  attr_reader :provider, :worker

  test '#perform calls DeleteServiceStatsWorker for all existing services' do
    worker.stubs(:build_jobs_deleted_services)

    DeleteServiceStatsWorker.expects(:perform_later).times(2).with(instance_of(Service))
    worker.perform(provider)
  end

  test '#perform calls DeleteServiceStatsWorker for all deleted services' do
    worker.stubs(:build_jobs_existing_services)

    DeleteServiceStatsWorker.expects(:perform_later).times(2).with(instance_of(::MissingModel::MissingService))
    worker.perform(provider)
  end
end
