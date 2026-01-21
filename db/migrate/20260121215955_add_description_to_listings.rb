class AddDescriptionToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :description, :text
  end
end
