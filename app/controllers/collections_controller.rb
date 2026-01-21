class CollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_collection, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_collection, only: [ :edit, :update, :destroy ]

  def index
    @collections = current_user.collections.includes(:collection_items)
  end

  def show
    @collection_items = @collection.collection_items.includes(:card)
  end

  def new
    @collection = current_user.collections.build
  end

  def create
    @collection = current_user.collections.build(collection_params)
    if @collection.save
      redirect_to @collection, notice: "Collection created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @collection.update(collection_params)
      redirect_to @collection, notice: "Collection updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection.destroy
    redirect_to collections_path, notice: "Collection deleted successfully."
  end

  private

  def set_collection
    @collection = Collection.find(params[:id])
  end

  def authorize_collection
    redirect_to collections_path, alert: "Not authorized." unless @collection.user == current_user
  end

  def collection_params
    params.require(:collection).permit(:name, :description, :public)
  end
end
