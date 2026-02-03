FactoryBot.define do
  factory :menu_daily_stat do
    menu
    aggregation_date { Date.current }
    total_quantity { 0 }
    total_sales_amount { 0 }
  end
end
