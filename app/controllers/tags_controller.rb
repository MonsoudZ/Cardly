class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tag, only: [ :edit, :update, :destroy ]

  def index
    @tags = current_user.tags.alphabetical.includes(:gift_cards)
    @untagged_count = current_user.gift_cards.untagged.count
  end

  def new
    @tag = current_user.tags.build
  end

  def create
    @tag = current_user.tags.build(tag_params)

    if @tag.save
      respond_to do |format|
        format.html { redirect_to tags_path, notice: "Tag created successfully." }
        format.turbo_stream
        format.json { render json: @tag, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @tag.update(tag_params)
      redirect_to tags_path, notice: "Tag updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tag.destroy
    redirect_to tags_path, notice: "Tag deleted."
  end

  # Create suggested tags for new users
  def create_suggestions
    Tag::SUGGESTED_TAGS.each do |suggestion|
      current_user.tags.find_or_create_by(name: suggestion[:name]) do |tag|
        tag.color = suggestion[:color]
      end
    end

    redirect_to tags_path, notice: "Suggested tags added to your collection."
  end

  private

  def set_tag
    @tag = current_user.tags.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :color)
  end
end
