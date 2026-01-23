class GiftCardMailer < ApplicationMailer
  # Send expiration reminder at various intervals
  def expiration_reminder(gift_card, days_remaining)
    @gift_card = gift_card
    @user = gift_card.user
    @brand = gift_card.brand
    @days_remaining = days_remaining

    subject = case days_remaining
    when 1
      "URGENT: Your #{@brand.name} gift card expires tomorrow!"
    when 7
      "Reminder: Your #{@brand.name} gift card expires in 1 week"
    else
      "Heads up: Your #{@brand.name} gift card expires in #{days_remaining} days"
    end

    mail(to: @user.email, subject: subject)
  end

  # Notify when a card has expired
  def card_expired(gift_card)
    @gift_card = gift_card
    @user = gift_card.user
    @brand = gift_card.brand

    mail(
      to: @user.email,
      subject: "Your #{@brand.name} gift card has expired"
    )
  end

  # Weekly digest of expiring cards
  def expiring_cards_digest(user, cards)
    @user = user
    @cards = cards

    mail(
      to: @user.email,
      subject: "#{cards.count} gift card(s) expiring soon"
    )
  end
end
