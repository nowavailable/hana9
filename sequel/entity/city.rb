class City < Sequel::Model
  one_to_many :cities_shops
  many_to_many :shops
end