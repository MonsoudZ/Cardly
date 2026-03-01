require "rails_helper"

RSpec.describe StripeWebhookEvent, type: :model do
  describe "processing state transitions" do
    let(:event) { described_class.create!(stripe_event_id: "evt_123", event_type: "checkout.session.completed") }

    it "keeps failed events retryable" do
      event.mark_as_failed!("temporary error")

      expect(event.reload.processed).to be false
      expect(event.error_message).to eq("temporary error")
    end

    it "clears previous errors on successful processing" do
      event.mark_as_failed!("temporary error")
      event.mark_as_processed!

      expect(event.reload.processed).to be true
      expect(event.error_message).to be_nil
    end
  end
end
