FactoryBot.define do
  factory :menu do
    name { Faker::Food.dish }
    price { Faker::Number.between(from: 500, to: 3000) }
    image_url { Faker::LoremFlickr.image(size: "300x300", search_terms: [ 'food' ]) }
    is_available { true }
    category { [ '前菜', 'メイン', 'デザート', 'ドリンク' ].sample }
  end
end
