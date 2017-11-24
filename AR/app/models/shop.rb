class Shop < ApplicationRecord
  has_many :cities_shops
  has_many :cities, through: :cities_shops
  has_many :rule_for_ships
  has_many :ship_limits
end
