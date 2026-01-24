class TransactionExpirationJob < ApplicationJob
  queue_as :default

  def perform
    expire_pending_transactions
    expire_countered_transactions
  end

  private

  def expire_pending_transactions
    Transaction.where("expires_at <= ?", Time.current)
               .where(status: "pending")
               .find_each do |transaction|
      begin
        transaction.expire!
        Rails.logger.info "Expired pending transaction #{transaction.id}"
      rescue => e
        Rails.logger.error("Failed to expire transaction #{transaction.id}: #{e.message}")
      end
    end
  end

  def expire_countered_transactions
    Transaction.where("expires_at <= ?", Time.current)
               .where(status: "countered")
               .find_each do |transaction|
      begin
        transaction.expire!
        Rails.logger.info "Expired countered transaction #{transaction.id}"
      rescue => e
        Rails.logger.error("Failed to expire transaction #{transaction.id}: #{e.message}")
      end
    end
  end
end
