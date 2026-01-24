class DisputesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [:new, :create]
  before_action :set_dispute, only: [:show, :add_message]
  before_action :authorize_dispute_access, only: [:show, :add_message]
  before_action :verify_can_create_dispute, only: [:new, :create]

  def index
    @disputes = current_user.disputes
                            .includes(card_transaction: { listing: { gift_card: :brand } })
                            .recent
    @open_disputes = @disputes.unresolved
    @resolved_disputes = @disputes.resolved
  end

  def show
    @messages = @dispute.dispute_messages.chronological.includes(:sender)
    mark_messages_as_read
  end

  def new
    @dispute = Dispute.new(card_transaction: @transaction, initiator: current_user)
  end

  def create
    @dispute = Dispute.new(dispute_params)
    @dispute.card_transaction = @transaction
    @dispute.initiator = current_user

    if @dispute.save
      redirect_to @dispute, notice: "Dispute opened successfully. We'll review your case shortly."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def add_message
    return redirect_to @dispute, alert: "Cannot add messages to a closed dispute." if @dispute.closed?

    @message = @dispute.dispute_messages.new(
      dispute_message_params.merge(sender: current_user)
    )

    if @message.save
      redirect_to @dispute, notice: "Message sent."
    else
      @messages = @dispute.dispute_messages.chronological.includes(:sender)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:transaction_id])
  end

  def set_dispute
    @dispute = Dispute.find(params[:id])
  end

  def authorize_dispute_access
    unless @dispute.participant?(current_user)
      redirect_to disputes_path, alert: "You don't have access to this dispute."
    end
  end

  def verify_can_create_dispute
    unless @transaction.can_be_disputed_by?(current_user)
      redirect_to transaction_path(@transaction),
                  alert: "You cannot open a dispute for this transaction."
    end
  end

  def dispute_params
    params.require(:dispute).permit(:reason, :description)
  end

  def dispute_message_params
    params.require(:dispute_message).permit(:content)
  end

  def mark_messages_as_read
    @dispute.dispute_messages
            .where.not(sender: current_user)
            .unread
            .update_all(read_at: Time.current)
  end
end
