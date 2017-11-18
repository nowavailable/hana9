class ShipLimit < Sequel::Model
  many_to_one :shop
end