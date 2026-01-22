require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user, name: "Regular User") }

  before { sign_in admin }

  describe "GET /admin/users" do
    it "displays all users" do
      user
      get admin_users_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Regular User")
    end

    it "allows searching by email" do
      user
      get admin_users_path, params: { search: user.email }

      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.email)
    end

    it "allows filtering by admin status" do
      user
      another_admin = create(:user, :admin, name: "Another Admin")

      get admin_users_path, params: { admin: "true" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Another Admin")
      expect(response.body).not_to include("Regular User")
    end
  end

  describe "GET /admin/users/:id" do
    it "displays user details" do
      get admin_user_path(user)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Regular User")
      expect(response.body).to include(user.email)
    end

    it "displays user stats" do
      get admin_user_path(user)

      expect(response.body).to include("Gift Cards")
      expect(response.body).to include("Active Listings")
      expect(response.body).to include("Completed Sales")
    end
  end

  describe "GET /admin/users/:id/edit" do
    it "displays the edit form" do
      get edit_admin_user_path(user)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit User")
    end
  end

  describe "PATCH /admin/users/:id" do
    it "updates user details" do
      patch admin_user_path(user), params: { user: { name: "Updated Name" } }

      expect(response).to redirect_to(admin_user_path(user))
      expect(user.reload.name).to eq("Updated Name")
    end

    it "handles invalid updates" do
      patch admin_user_path(user), params: { user: { email: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/users/:id" do
    it "deletes the user" do
      user
      expect {
        delete admin_user_path(user)
      }.to change(User, :count).by(-1)

      expect(response).to redirect_to(admin_users_path)
    end

    it "prevents deleting yourself" do
      expect {
        delete admin_user_path(admin)
      }.not_to change(User, :count)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to eq("You cannot delete yourself.")
    end
  end

  describe "POST /admin/users/:id/toggle_admin" do
    it "grants admin access to regular user" do
      post toggle_admin_admin_user_path(user)

      expect(response).to redirect_to(admin_user_path(user))
      expect(user.reload.admin?).to be true
    end

    it "removes admin access from admin user" do
      another_admin = create(:user, :admin)
      post toggle_admin_admin_user_path(another_admin)

      expect(response).to redirect_to(admin_user_path(another_admin))
      expect(another_admin.reload.admin?).to be false
    end

    it "prevents changing your own admin status" do
      post toggle_admin_admin_user_path(admin)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to eq("You cannot change your own admin status.")
      expect(admin.reload.admin?).to be true
    end
  end

  context "when not an admin" do
    before { sign_in user }

    it "denies access to users index" do
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end
end
