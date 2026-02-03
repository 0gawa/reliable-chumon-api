class MenuDailyStat < ApplicationRecord
  belongs_to :menu

  validates :aggregation_date, presence: true
  validates :total_quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_sales_amount, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :by_date_range, ->(start_date, end_date) { where(aggregation_date: start_date..end_date) }
  scope :by_menu, ->(menu_id) { where(menu_id: menu_id) }
  scope :recent, ->(days = 30) { where("aggregation_date >= ?", days.days.ago.to_date).order(aggregation_date: :desc) }
  scope :ordered_by_date, -> { order(aggregation_date: :desc) }
end
