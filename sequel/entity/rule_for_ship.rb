class RuleForShip < Sequel::Model
  many_to_one :shop
  many_to_one :merchandise

end