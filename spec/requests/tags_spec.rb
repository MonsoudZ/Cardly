require 'rails_helper'

RSpec.describe "Tags", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /tags" do
    it "displays the tags index" do
      create(:tag, :groceries, user: user)
      create(:tag, :restaurants, user: user)

      get tags_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Groceries")
      expect(response.body).to include("Restaurants")
    end

    it "shows untagged cards count" do
      create(:tag, user: user)  # Need at least one tag for the untagged section to show
      brand = create(:brand)
      create(:gift_card, user: user, brand: brand)

      get tags_path

      expect(response.body).to include("Untagged")
    end
  end

  describe "GET /tags/new" do
    it "displays the new tag form" do
      get new_tag_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("New Tag")
    end
  end

  describe "POST /tags" do
    it "creates a new tag" do
      expect {
        post tags_path, params: { tag: { name: "Shopping", color: "#EC4899" } }
      }.to change(Tag, :count).by(1)

      expect(response).to redirect_to(tags_path)
      expect(Tag.last.name).to eq("Shopping")
    end

    it "handles invalid tag" do
      post tags_path, params: { tag: { name: "", color: "#EC4899" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /tags/:id/edit" do
    it "displays the edit form" do
      tag = create(:tag, :groceries, user: user)

      get edit_tag_path(tag)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Tag")
    end
  end

  describe "PATCH /tags/:id" do
    it "updates the tag" do
      tag = create(:tag, user: user, name: "Old Name")

      patch tag_path(tag), params: { tag: { name: "New Name" } }

      expect(response).to redirect_to(tags_path)
      expect(tag.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /tags/:id" do
    it "deletes the tag" do
      tag = create(:tag, :groceries, user: user)

      expect {
        delete tag_path(tag)
      }.to change(Tag, :count).by(-1)

      expect(response).to redirect_to(tags_path)
    end
  end

  describe "POST /tags/create_suggestions" do
    it "creates suggested tags" do
      expect {
        post create_suggestions_tags_path
      }.to change(Tag, :count).by(Tag::SUGGESTED_TAGS.count)

      expect(response).to redirect_to(tags_path)
      expect(user.tags.pluck(:name)).to include("Groceries", "Restaurants")
    end

    it "does not duplicate existing tags" do
      create(:tag, :groceries, user: user)

      post create_suggestions_tags_path

      expect(user.tags.where(name: "Groceries").count).to eq(1)
    end
  end

  context "when accessing another user's tags" do
    let(:other_user) { create(:user) }
    let(:other_tag) { create(:tag, user: other_user) }

    it "denies access to edit" do
      get edit_tag_path(other_tag)
      expect(response).to have_http_status(:not_found)
    end
  end
end
