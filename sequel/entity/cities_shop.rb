class CitiesShop < Sequel::Model
  many_to_one :shop
  many_to_one :city
end