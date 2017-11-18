class OrderDetail < Sequel::Model
  many_to_one :order
  many_to_one :merchandise
  many_to_one :city

end