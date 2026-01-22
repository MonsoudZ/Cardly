require "rails_helper"

RSpec.describe "Marketplace", type: :request do
  describe "GET /marketplace" do
    it "returns http success" do
      get marketplace_path
      expect(response).to have_http_status(:success)
    end

    it "displays marketplace heading" do
      get marketplace_path
      expect(response.body).to include("Marketplace")
    end
  end

  describe "GET /marketplace/sales" do
    it "returns http success" do
      get marketplace_sales_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /marketplace/trades" do
    it "returns http success" do
      get marketplace_trades_path
      expect(response).to have_http_status(:success)
    end
  end
end
