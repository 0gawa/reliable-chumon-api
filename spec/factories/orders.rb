FactoryBot.define do
  factory :order do
    table_number { "#{('A'..'Z').to_a.sample}-#{rand(1..20)}" }
    total_amount { 3520 }
    tax_amount { 320 }
    status { 'pending' }
    ordered_at { Time.current }

    # デフォルトで1つのorder_itemを作成
    transient do
      items_count { 1 }
    end

    after(:create) do |order, evaluator|
      create_list(:order_item, evaluator.items_count, order: order) if evaluator.items_count > 0
    end

    trait :confirmed do
      status { 'confirmed' }
    end

    trait :completed do
      status { 'completed' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :no_items do
      items_count { 0 }
    end
  end
end
