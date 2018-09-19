# frozen_string_literal: true

class FindAndSuspendInactiveAccountsWorker
  include Sidekiq::Worker

  def perform
    Account.where.has { created_at <= 1.year.ago }.where.has {
      not_exists Cinstance.where.has { user_account_id == BabySqueel[:accounts].id }
                     .where.has { first_daily_traffic_at >= 1.year.ago }
    }.destroy_all # TODO: this is neither the final behaviour, not the final way to do it, but step by step :)
  end
end
