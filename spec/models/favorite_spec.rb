require "rails_helper"

RSpec.describe Favorite, type: :model do
  describe "validations" do
    let(:user) { create(:user) }
    let(:listing) { create(:listing) }

    subject { build(:favorite, user: user, listing: listing) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires user" do
      subject.user = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:user]).to include("must exist")
    end

    it "requires listing" do
      subject.listing = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:listing]).to include("must exist")
    end

    it "prevents user from favoriting same listing twice" do
      create(:favorite, user: user, listing: listing)
      duplicate = build(:favorite, user: user, listing: listing)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:listing_id]).to include("already in your watchlist")
    end

    it "allows different users to favorite same listing" do
      create(:favorite, user: user, listing: listing)
      other_user = create(:user)
      other_favorite = build(:favorite, user: other_user, listing: listing)
      expect(other_favorite).to be_valid
    end
  end

  describe "scopes" do
    describe ".active_listings" do
      let!(:active_listing) { create(:listing, status: "active") }
      let!(:cancelled_listing) { create(:listing, :cancelled) }
      let(:user) { create(:user) }

      before do
        create(:favorite, user: user, listing: active_listing)
        create(:favorite, user: user, listing: cancelled_listing)
      end

      it "returns favorites with active listings" do
        expect(Favorite.active_listings.map(&:listing)).to include(active_listing)
        expect(Favorite.active_listings.map(&:listing)).not_to include(cancelled_listing)
      end
    end
  end

  describe "User#favorited?" do
    let(:user) { create(:user) }
    let(:listing) { create(:listing) }

    it "returns true when favorite exists" do
      create(:favorite, user: user, listing: listing)
      expect(user.favorited?(listing)).to be true
    end

    it "returns false when no favorite" do
      expect(user.favorited?(listing)).to be false
    end
  end
end
