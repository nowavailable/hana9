class Shop < Sequel::Model
  one_to_many :cities_shops
  many_to_many :cities
  one_to_many :rule_for_ships
  one_to_many :ship_limits

end