# frozen_string_literal: true

class FindAndScheduleForDeletionSuspendedAccountsWorker
  include Sidekiq::Worker

  def perform
    Account.providers_without_master.suspended_since_time_ago.find_each(&:schedule_for_deletion!)
  end
end
