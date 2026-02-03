class Menu < ApplicationRecord
  has_many :menu_daily_stats, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :is_available, inclusion: { in: [ true, false ] }
  validates :category, length: { maximum: 50 }, allow_blank: true

  scope :available, -> { where(is_available: true) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
end
