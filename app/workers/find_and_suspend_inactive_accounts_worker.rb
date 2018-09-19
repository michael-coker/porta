# frozen_string_literal: true

class FindAndSuspendInactiveAccountsWorker
  include Sidekiq::Worker

  def perform
    Account.inactive_since_time_ago.destroy_all # TODO: this is neither the final behaviour, not the final way to do it, but step by step :)
  end
end
