class CreateBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :brands do |t|
      t.string :name, null: false
      t.string :logo_url
      t.string :website_url
      t.string :category, default: "retail"
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :brands, :name, unique: true
    add_index :brands, :category
    add_index :brands, :active
  end
end
