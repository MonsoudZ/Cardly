class CollectionItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_collection
  before_action :authorize_collection
  before_action :set_collection_item, only: [ :edit, :update, :destroy ]

  def new
    @collection_item = @collection.collection_items.build
    @cards = available_cards
  end

  def create
    @collection_item = @collection.collection_items.build(collection_item_params)

    if @collection_item.save
      redirect_to @collection, notice: "Card added to collection successfully."
    else
      @cards = available_cards
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @cards = available_cards_for_edit
  end

  def update
    if @collection_item.update(collection_item_params)
      redirect_to @collection, notice: "Card updated successfully."
    else
      @cards = available_cards_for_edit
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection_item.destroy
    redirect_to @collection, notice: "Card removed from collection."
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def authorize_collection
    redirect_to collections_path, alert: "Not authorized." unless @collection.user == current_user
  end

  def set_collection_item
    @collection_item = @collection.collection_items.find(params[:id])
  end

  def collection_item_params
    params.require(:collection_item).permit(
      :card_id, :condition, :quantity, :acquired_price,
      :acquired_date, :for_trade, :for_sale, :asking_price, :notes
    )
  end

  def available_cards
    # Cards not already in this collection
    existing_card_ids = @collection.collection_items.pluck(:card_id)
    Card.where.not(id: existing_card_ids).order(:name)
  end

  def available_cards_for_edit
    # Include current card plus cards not in collection
    existing_card_ids = @collection.collection_items.where.not(id: @collection_item.id).pluck(:card_id)
    Card.where.not(id: existing_card_ids).order(:name)
  end
end
