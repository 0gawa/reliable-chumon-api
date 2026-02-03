class OrderItem < ApplicationRecord
  belongs_to :order

  validates :menu_snapshot, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :subtotal, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def menu_name
    menu_snapshot["name"]
  end

  def menu_price
    menu_snapshot["price"]
  end

  def menu_id
    menu_snapshot["id"]
  end
end
