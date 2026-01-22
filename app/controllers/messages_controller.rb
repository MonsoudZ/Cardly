class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction
  before_action :ensure_participant

  def create
    @message = @transaction.messages.build(message_params)
    @message.sender = current_user

    respond_to do |format|
      if @message.save
        format.html { redirect_to transaction_path(@transaction, anchor: "messages"), notice: "Message sent." }
        format.turbo_stream
      else
        format.html { redirect_to transaction_path(@transaction), alert: "Could not send message." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { transaction: @transaction, message: @message }) }
      end
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:transaction_id])
  end

  def ensure_participant
    unless @transaction.participant?(current_user)
      redirect_to transactions_path, alert: "You don't have access to this transaction."
    end
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
