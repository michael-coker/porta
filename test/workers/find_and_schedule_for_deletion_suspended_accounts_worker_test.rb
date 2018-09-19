require 'test_helper'
class FindAndScheduleForDeletionSuspendedAccountsWorkerTest < ActiveSupport::TestCase
  setup do
    @accounts = FactoryGirl.create_list(:simple_provider, 3)
    @accounts[0..1].each(&:suspend!)
    @accounts.values_at(0, -1).each { |account| account.update_attribute(:updated_at, 91.days.ago) }
  end

  test 'perform schedules for deletion suspended accounts' do
    FindAndScheduleForDeletionSuspendedAccountsWorker.new.perform
    assert @accounts.first.reload.scheduled_for_deletion?
    @accounts[1..-1].each { |account| refute account.reload.scheduled_for_deletion? }
  end
end
