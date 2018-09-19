require 'test_helper'
class FindAndSuspendInactiveAccountsWorkerTest < ActiveSupport::TestCase
  setup do
    @cinstances = FactoryGirl.create_list(:cinstance, 4)
    created_at_time_ago = [2.years.ago, 2.years.ago, 6.months.ago, 6.months.ago]
    @cinstances.each_with_index { |cinstance, index| cinstance.user_account.update_attribute(:created_at, created_at_time_ago[index]) }
    daily_traffic_at_months_ago = [18, 2]
    @cinstances.each_with_index do |cinstance, index|
      cinstance.update_attribute(:first_daily_traffic_at, daily_traffic_at_months_ago[index % 2].months.ago)
    end
  end

  test 'perform destroys inactive accounts' do # TODO: this is not the final behaviour, but step by step :)
    assert_difference Account.method(:count), -1 do
      FindAndSuspendInactiveAccountsWorker.new.perform
    end
    assert_raise(ActiveRecord::RecordNotFound) { @cinstances.first.user_account.reload }
  end
end
