class GiftCardTag < ApplicationRecord
  belongs_to :gift_card
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :gift_card_id }
  validate :tag_belongs_to_card_owner

  private

  def tag_belongs_to_card_owner
    return unless gift_card && tag

    if gift_card.user_id != tag.user_id
      errors.add(:tag, "must belong to the card owner")
    end
  end
end
