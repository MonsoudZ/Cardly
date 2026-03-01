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
        from_date = parse_date(params[:from])
        @transactions = @transactions.where("created_at >= ?", from_date.beginning_of_day) if from_date
      end
      if params[:to].present?
        to_date = parse_date(params[:to])
        @transactions = @transactions.where("created_at <= ?", to_date.end_of_day) if to_date
      end

      @transactions = @transactions.page(params[:page]).per(25)

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

    def parse_date(value)
      Date.iso8601(value)
    rescue ArgumentError
      nil
    end
  end
end
