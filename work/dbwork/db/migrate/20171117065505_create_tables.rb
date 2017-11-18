class CreateTables < ActiveRecord::Migration[5.1]
  def change
    create_table :shops do |t|
      t.string :code, null: false
      t.string :label, null: false
      t.string :delivery_limit_per_day, null: false
      t.string :mergin, null: false
    end
    add_index :shops, [:code], unique: true

    create_table :cities do |t|
      t.string :label, null: false
    end

    create_table :cities_shops do |t|
      t.references :shop, null: false
      t.references :city, null: false
    end
    add_index :cities_shops, [:shop_id, :city_id], unique: true

    create_table :rule_for_ships do |t|
      t.references :shop, null: false
      t.references :merchandise, null: false
      t.integer :interval_day, null: false
      t.integer :quantity_limit, null: false
      t.integer :quantity_available, null: false
    end
    add_index :rule_for_ships, [:shop_id, :merchandise_id], unique: true

    create_table :merchandises do |t|
      t.string :label, null: false
      t.integer :price, null: false
    end

    create_table :orders do |t|
      t.string :order_code, null: false
      t.datetime :ordered_at, null: false
    end
    add_index :orders, [:order_code], unique: true

    create_table :order_details do |t|
      t.string :seq_code, null: false
      t.references :order, null: false
      t.references :merchandise, null: false
      t.date :expected_date, null: false
      t.integer :quantity, null: false
      t.references :city, null: false
    end
    add_index :order_details, [:seq_code, :order_id, :merchandise_id], unique: true

    create_table :requested_deliveries do |t|
      t.references :shop, null: false
      t.string :order_code, null: false
      t.references :order_detail, null: false
    end
    add_index :requested_deliveries, [:shop_id, :order_detail_id], unique: true
    add_index :requested_deliveries, [:order_code], unique: false

    create_table :ship_limits do |t|
      t.references :shop, null: false
      t.date :expected_date, null: false
    end
    add_index :ship_limits, [:shop_id, :expected_date], unique: true
  end
end
