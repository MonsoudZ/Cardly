class DropTradingCardTables < ActiveRecord::Migration[8.1]
  def change
    drop_table :collection_items, if_exists: true
    drop_table :collections, if_exists: true
    drop_table :cards, if_exists: true
  end
end
