module Admin
  class DisputesController < BaseController
    before_action :set_dispute, only: [:show, :review, :resolve, :close, :reopen, :add_message]

    def index
      @disputes = Dispute.includes(
        :initiator,
        card_transaction: [:buyer, :seller, { listing: { gift_card: :brand } }]
      ).recent

      case params[:status]
      when "open"
        @disputes = @disputes.open_disputes
      when "under_review"
        @disputes = @disputes.under_review
      when "resolved"
        @disputes = @disputes.resolved
      when "closed"
        @disputes = @disputes.where(status: "closed")
      end

      @stats = {
        total: Dispute.count,
        open: Dispute.open_disputes.count,
        under_review: Dispute.under_review.count,
        resolved: Dispute.resolved.count
      }
    end

    def show
      @messages = @dispute.dispute_messages.chronological.includes(:sender)
      @buyer = @dispute.buyer
      @seller = @dispute.seller
      @transaction = @dispute.card_transaction
    end

    def review
      if @dispute.mark_under_review!(current_user)
        redirect_to admin_dispute_path(@dispute),
                    notice: "Dispute is now under review."
      else
        redirect_to admin_dispute_path(@dispute),
                    alert: "Could not update dispute status."
      end
    end

    def resolve
      resolution_params = dispute_resolution_params
      resolution = resolution_params[:resolution]
      resolution_notes = resolution_params[:resolution_notes]

      # Validate resolution type at controller level
      unless Dispute::RESOLUTIONS.include?(resolution)
        redirect_to admin_dispute_path(@dispute),
                    alert: "Invalid resolution type. Please select a valid resolution."
        return
      end

      if @dispute.resolve!(resolution, resolution_notes, current_user)
        redirect_to admin_dispute_path(@dispute),
                    notice: "Dispute resolved successfully."
      else
        redirect_to admin_dispute_path(@dispute),
                    alert: "Could not resolve dispute. Please select a valid resolution."
      end
    end

    def close
      admin_notes = dispute_close_params[:admin_notes]
      if @dispute.close!(admin_notes)
        redirect_to admin_disputes_path,
                    notice: "Dispute closed."
      else
        redirect_to admin_dispute_path(@dispute),
                    alert: "Could not close dispute."
      end
    end

    def reopen
      if @dispute.reopen!
        redirect_to admin_dispute_path(@dispute),
                    notice: "Dispute reopened."
      else
        redirect_to admin_dispute_path(@dispute),
                    alert: "Could not reopen dispute."
      end
    end

    def add_message
      @message = @dispute.dispute_messages.new(
        dispute_message_params.merge(
          sender: current_user,
          is_admin_message: true
        )
      )

      if @message.save
        redirect_to admin_dispute_path(@dispute), notice: "Admin message sent."
      else
        @messages = @dispute.dispute_messages.chronological.includes(:sender)
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_dispute
      @dispute = Dispute.find(params[:id])
    end

    def dispute_resolution_params
      params.permit(:resolution, :resolution_notes)
    end

    def dispute_close_params
      params.permit(:admin_notes)
    end

    def dispute_message_params
      params.require(:dispute_message).permit(:content)
    end
  end
end
