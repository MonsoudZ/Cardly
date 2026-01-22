class MessageMailer < ApplicationMailer
  def new_message(message)
    @message = message
    @sender = message.sender
    @recipient = message.recipient
    @transaction = message.transaction

    mail(
      to: @recipient.email,
      subject: "New message from #{@sender.display_name} about your #{@transaction.brand_name} transaction"
    )
  end
end
