class Order < Sequel::Model
  one_to_many :order_details

end