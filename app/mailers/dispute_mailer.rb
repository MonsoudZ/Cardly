class DisputeMailer < ApplicationMailer
  def dispute_opened(dispute)
    @dispute = dispute
    @user = dispute.initiator
    @transaction = dispute.card_transaction

    mail(
      to: @user.email,
      subject: "Dispute ##{dispute.id} - Your dispute has been opened"
    )
  end

  def dispute_opened_to_other_party(dispute)
    @dispute = dispute
    @user = dispute.other_party
    @transaction = dispute.card_transaction

    mail(
      to: @user.email,
      subject: "Dispute ##{dispute.id} - A dispute has been opened for your transaction"
    )
  end

  def dispute_status_changed(dispute)
    @dispute = dispute
    @transaction = dispute.card_transaction

    [dispute.buyer, dispute.seller].each do |user|
      @user = user
      mail(
        to: user.email,
        subject: "Dispute ##{dispute.id} - Status updated to #{dispute.status.titleize}"
      )
    end
  end

  def new_message(dispute_message, recipient)
    @message = dispute_message
    @dispute = dispute_message.dispute
    @user = recipient
    @sender = dispute_message.sender

    mail(
      to: recipient.email,
      subject: "Dispute ##{@dispute.id} - New message from #{@sender.display_name}"
    )
  end

  def dispute_resolved(dispute)
    @dispute = dispute
    @transaction = dispute.card_transaction

    [dispute.buyer, dispute.seller].each do |user|
      @user = user
      mail(
        to: user.email,
        subject: "Dispute ##{dispute.id} - Resolved: #{dispute.resolution_display}"
      )
    end
  end
end
