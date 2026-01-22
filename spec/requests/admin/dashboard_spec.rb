require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    context "when not logged in" do
      it "redirects to login" do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as regular user" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "redirects to root with alert" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to access this area.")
      end
    end

    context "when logged in as admin" do
      let(:admin) { create(:user, :admin) }

      before { sign_in admin }

      it "displays the admin dashboard" do
        get admin_root_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Dashboard")
      end

      it "displays key metrics" do
        create_list(:user, 3)

        get admin_root_path

        expect(response.body).to include("Total Users")
        expect(response.body).to include("Total Listings")
        expect(response.body).to include("Total Transactions")
      end

      it "displays recent activity" do
        get admin_root_path

        expect(response.body).to include("Recent Users")
        expect(response.body).to include("Recent Transactions")
        expect(response.body).to include("Recent Listings")
      end
    end
  end
end
