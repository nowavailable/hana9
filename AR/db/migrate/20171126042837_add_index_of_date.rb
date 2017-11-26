class AddIndexOfDate < ActiveRecord::Migration[5.1]
  def change
    add_index :order_details, :expected_date
  end
end
