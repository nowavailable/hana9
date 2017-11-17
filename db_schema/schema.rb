# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171117065505) do

  create_table "cities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "label", null: false
  end

  create_table "cities_shops", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "shop_id", null: false
    t.bigint "city_id", null: false
    t.index ["city_id"], name: "index_cities_shops_on_city_id"
    t.index ["shop_id", "city_id"], name: "index_cities_shops_on_shop_id_and_city_id", unique: true
    t.index ["shop_id"], name: "index_cities_shops_on_shop_id"
  end

  create_table "merchandises", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "label", null: false
    t.integer "price", null: false
  end

  create_table "order_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "seq_code", null: false
    t.bigint "order_id", null: false
    t.bigint "merchandise_id", null: false
    t.date "expected_date", null: false
    t.integer "quantity", null: false
    t.bigint "city_id", null: false
    t.index ["city_id"], name: "index_order_details_on_city_id"
    t.index ["merchandise_id"], name: "index_order_details_on_merchandise_id"
    t.index ["order_id"], name: "index_order_details_on_order_id"
    t.index ["seq_code", "order_id", "merchandise_id"], name: "index_order_details_on_seq_code_and_order_id_and_merchandise_id", unique: true
  end

  create_table "orders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "order_code", null: false
    t.datetime "ordered_at", null: false
    t.index ["order_code"], name: "index_orders_on_order_code", unique: true
  end

  create_table "request_deliveries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "shop_id", null: false
    t.string "order_code", null: false
    t.bigint "order_detail_id", null: false
    t.index ["order_code"], name: "index_request_deliveries_on_order_code"
    t.index ["order_detail_id"], name: "index_request_deliveries_on_order_detail_id"
    t.index ["shop_id", "order_detail_id"], name: "index_request_deliveries_on_shop_id_and_order_detail_id", unique: true
    t.index ["shop_id"], name: "index_request_deliveries_on_shop_id"
  end

  create_table "rule_for_ships", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "shop_id", null: false
    t.bigint "merchandise_id", null: false
    t.integer "interval_day", null: false
    t.integer "quantity_limit", null: false
    t.integer "quantity_available", null: false
    t.index ["merchandise_id"], name: "index_rule_for_ships_on_merchandise_id"
    t.index ["shop_id", "merchandise_id"], name: "index_rule_for_ships_on_shop_id_and_merchandise_id", unique: true
    t.index ["shop_id"], name: "index_rule_for_ships_on_shop_id"
  end

  create_table "ship_limit", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "shop_id", null: false
    t.date "expected_date", null: false
    t.index ["shop_id", "expected_date"], name: "index_ship_limit_on_shop_id_and_expected_date", unique: true
    t.index ["shop_id"], name: "index_ship_limit_on_shop_id"
  end

  create_table "shops", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "code", null: false
    t.string "label", null: false
    t.string "delivery_limit_per_day", null: false
    t.string "mergin", null: false
    t.index ["code"], name: "index_shops_on_code", unique: true
  end

end
