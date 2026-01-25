module Admin
  class TransactionsController < BaseController
    before_action :set_transaction, only: [ :show ]

    def index
      @transactions = Transaction.includes(:buyer, :seller, listing: { gift_card: :brand })
                                  .order(created_at: :desc)

      # Filter by status
      if params[:status].present?
        @transactions = @transactions.where(status: params[:status])
      end

      # Filter by type
      if params[:type].present?
        @transactions = @transactions.where(transaction_type: params[:type])
      end

      # Date range
      if params[:from].present?
        @transactions = @transactions.where("created_at >= ?", Date.parse(params[:from]).beginning_of_day)
      end
      if params[:to].present?
        @transactions = @transactions.where("created_at <= ?", Date.parse(params[:to]).end_of_day)
      end

      @transactions = @transactions.limit(50)

      # Summary stats
      @total_value = @transactions.where(status: "completed").sum(:amount)
      @pending_count = Transaction.pending.count
    end

    def show
      @messages = @transaction.messages.includes(:sender).order(created_at: :asc)
      @ratings = @transaction.ratings.includes(:rater, :ratee)
    end

    private

    def set_transaction
      @transaction = Transaction.find(params[:id])
    end
  end
end
