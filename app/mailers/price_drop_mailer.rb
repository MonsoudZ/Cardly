class PriceDropMailer < ApplicationMailer
  include ActionView::Helpers::NumberHelper

  # Notify user when a watched listing drops in price
  def price_drop_alert(user, listing, old_price, new_price)
    @user = user
    @listing = listing
    @old_price = old_price
    @new_price = new_price
    @savings = old_price - new_price
    @savings_percentage = ((old_price - new_price) / old_price * 100).round

    mail(
      to: @user.email,
      subject: "Price drop alert: #{@listing.brand_name} gift card now #{number_to_currency(@new_price)}!"
    )
  end
end
