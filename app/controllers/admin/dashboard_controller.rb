module Admin
  class DashboardController < BaseController
    def index
      # Key metrics
      @total_users = User.count
      @new_users_today = User.where("created_at >= ?", Time.current.beginning_of_day).count
      @new_users_this_week = User.where("created_at >= ?", 1.week.ago).count

      @total_listings = Listing.count
      @active_listings = Listing.active.count
      @listings_today = Listing.where("created_at >= ?", Time.current.beginning_of_day).count

      @total_transactions = Transaction.count
      @completed_transactions = Transaction.where(status: "completed").count
      @pending_transactions = Transaction.where(status: "pending").count
      @transactions_today = Transaction.where("created_at >= ?", Time.current.beginning_of_day).count

      @total_gift_cards = GiftCard.count
      @total_gift_card_value = GiftCard.sum(:balance)

      # Recent activity
      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_transactions = Transaction.includes(:buyer, :seller, listing: { gift_card: :brand })
                                         .order(created_at: :desc)
                                         .limit(10)
      @recent_listings = Listing.includes(:user, gift_card: :brand)
                                .order(created_at: :desc)
                                .limit(10)

      # Transaction stats by status
      @transaction_stats = Transaction.group(:status).count

      # Weekly transaction volume (last 7 days)
      @weekly_transactions = Transaction.where("created_at >= ?", 7.days.ago)
                                         .group("DATE(created_at)")
                                         .count

      # Top sellers by completed sales
      @top_sellers = User.joins(:sales)
                         .where(transactions: { status: "completed" })
                         .group("users.id")
                         .order("count_all DESC")
                         .limit(5)
                         .count
    end
  end
end
