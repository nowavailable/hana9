class Shop < ApplicationRecord
  has_many :cities_shops
  has_many :cities, through: :cities_shops
  has_many :rule_for_ships
  has_many :ship_limits
  has_many :requested_deliveries

  # class << self
  #   def constraint_delivery_arel(order_detail, aliase_name)
  #     Shop.as(aliase_name).eager_load(
  #       :order_details => :requested_deliveries
  #     ).where(
  #       order_details: {:requested_deliveries =>
  #         {expected_date: order_detail.expected_date}}
  #     ).select(
  #       "shops.id AS shop_id," +
  #         "COUNT(requested_deliveries.id), shops.delivery_limit_per_day"
  #     ).where(
  #       "COUNT(requested_deliveries.id) < shops.delivery_limit_per_day"
  #     )
  #   end
  #
  #   def constraint_quantity_arel(order_detail, aliase_name)
  #     days_remaining = (order_detail.expected_date - Date.today).to_i
  #     Shop.as("shop_resource_quantity").eager_load(
  #       :cities, :rule_for_ships
  #     ).where(
  #       cities: {id: order_detail.city_id},
  #       rule_for_ships: {id: order_detail.merchandise_id}
  #     ).select("shops.id AS shop_id").group(
  #       "rule_for_ships.merchandise_id"
  #     ).having(
  #       "SUM(IF rule_for_ships.interval_day <= #{days_remaining} THEN " +
  #         "rule_for_ships.quantity_limit ELSE " +
  #         "rule_for_ships.quantity_available END " +
  #         ") >= #{order_detail.quantity}"
  #     ).joins(
  #       "INNER JOIN #{constraint_delivery_arel.to_sql} ON " +
  #         "shop_resouce_delivery.shop_id = shop_resource_quantity.shop_id"
  #     )
  #   end
  # end

end
