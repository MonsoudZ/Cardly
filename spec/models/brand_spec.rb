require "rails_helper"

RSpec.describe Brand, type: :model do
  describe "validations" do
    subject { build(:brand) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a name" do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it "requires unique name" do
      create(:brand, name: "Amazon")
      subject.name = "Amazon"
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("has already been taken")
    end

    it "requires valid category" do
      subject.category = "invalid"
      expect(subject).not_to be_valid
      expect(subject.errors[:category]).to include("is not included in the list")
    end
  end

  describe "scopes" do
    let!(:active_brand) { create(:brand, active: true) }
    let!(:inactive_brand) { create(:brand, :inactive) }
    let!(:retail_brand) { create(:brand, :retail) }
    let!(:food_brand) { create(:brand, :food) }

    describe ".active" do
      it "returns only active brands" do
        expect(Brand.active).to include(active_brand)
        expect(Brand.active).not_to include(inactive_brand)
      end
    end

    describe ".by_category" do
      it "filters by category" do
        expect(Brand.by_category("retail")).to include(retail_brand)
        expect(Brand.by_category("retail")).not_to include(food_brand)
      end
    end
  end

  describe "#display_logo" do
    it "returns logo_url if present" do
      brand = build(:brand, logo_url: "https://example.com/logo.png")
      expect(brand.display_logo).to eq("https://example.com/logo.png")
    end

    it "returns placeholder if logo_url is blank" do
      brand = build(:brand, name: "Test Brand", logo_url: nil)
      expect(brand.display_logo).to include("placehold.co")
      expect(brand.display_logo).to include("TES")
    end
  end
end
