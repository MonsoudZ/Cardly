class MarketplaceController < ApplicationController
  def index
    @items_for_sale = CollectionItem.for_sale
                                     .joins(collection: :user)
                                     .includes(:card, collection: :user)
                                     .order(created_at: :desc)

    @items_for_trade = CollectionItem.for_trade
                                      .joins(collection: :user)
                                      .includes(:card, collection: :user)
                                      .order(created_at: :desc)

    # Filter by card type if specified
    if params[:card_type].present?
      @items_for_sale = @items_for_sale.joins(:card).where(cards: { card_type: params[:card_type] })
      @items_for_trade = @items_for_trade.joins(:card).where(cards: { card_type: params[:card_type] })
    end
  end
end
