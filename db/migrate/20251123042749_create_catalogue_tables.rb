class CreateCatalogueTables < ActiveRecord::Migration[8.0]
  def change
    create_table :catalogs do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.date :start_date
      t.date :end_date
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :catalogs, :identifier, unique: true
    add_index :catalogs, :active

    create_table :sections do |t|
      t.string :identifier, null: false
      t.references :catalog, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :sections }
      t.string :name, null: false
      t.text :description
      t.integer :display_order, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.string :image_url
      t.timestamps
    end

    add_index :sections, :identifier, unique: true
    add_index :sections, :active
    add_index :sections, [ :catalog_id, :display_order ]

    create_table :items do |t|
      t.string :sku, null: false
      t.references :section, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: 'USD'
      t.integer :display_order, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.string :image_url
      t.timestamps
    end

    add_index :items, :sku, unique: true
    add_index :items, :active
    add_index :items, [ :section_id, :display_order ]

    create_table :options do |t|
      t.references :item, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, default: 0, null: false
      t.string :currency, null: false, default: 'USD'
      t.integer :display_order, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :options, :active
    add_index :options, [ :item_id, :display_order ]
  end
end
