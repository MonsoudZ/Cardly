class ExpirationReminderJob < ApplicationJob
  queue_as :default

  def perform
    send_30_day_reminders
    send_7_day_reminders
    send_1_day_reminders
    mark_expired_cards
  end

  private

  def send_30_day_reminders
    GiftCard.needs_30_day_reminder.includes(:user, :brand).find_each do |card|
      GiftCardMailer.expiration_reminder(card, 30).deliver_later
      card.update!(reminder_sent_at: Time.current)
      Rails.logger.info "Sent 30-day expiration reminder for card #{card.id}"
    end
  end

  def send_7_day_reminders
    GiftCard.needs_7_day_reminder.includes(:user, :brand).find_each do |card|
      GiftCardMailer.expiration_reminder(card, 7).deliver_later
      card.update!(reminder_7_day_sent_at: Time.current)
      Rails.logger.info "Sent 7-day expiration reminder for card #{card.id}"
    end
  end

  def send_1_day_reminders
    GiftCard.needs_1_day_reminder.includes(:user, :brand).find_each do |card|
      GiftCardMailer.expiration_reminder(card, 1).deliver_later
      card.update!(reminder_1_day_sent_at: Time.current)
      Rails.logger.info "Sent 1-day expiration reminder for card #{card.id}"
    end
  end

  def mark_expired_cards
    GiftCard.where("expiration_date < ?", Date.current)
            .where.not(status: "expired")
            .find_each do |card|
      card.update!(status: "expired")
      GiftCardMailer.card_expired(card).deliver_later
      Rails.logger.info "Marked card #{card.id} as expired"
    end
  end
end
