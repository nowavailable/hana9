class City < Sequel::Model
  many_to_one :cities_shops
  many_to_many :shops
end