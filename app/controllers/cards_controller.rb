class CardsController < ApplicationController
  def index
    @cards = Card.all

    @cards = @cards.by_type(params[:card_type]) if params[:card_type].present?
    @cards = @cards.by_set(params[:set_name]) if params[:set_name].present?
    @cards = @cards.by_rarity(params[:rarity]) if params[:rarity].present?

    @cards = @cards.order(:name)
  end

  def show
    @card = Card.find(params[:id])
  end
end
