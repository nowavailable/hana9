class City < ApplicationRecord
  has_many :cities_shops
  has_many :shops, through: :cities_shops
end
