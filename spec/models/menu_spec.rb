require 'rails_helper'

RSpec.describe Menu, type: :model do
  describe 'バリデーション' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).only_integer.is_greater_than(0) }
    it { should validate_length_of(:name).is_at_most(100) }
    it { should validate_length_of(:category).is_at_most(50) }
  end

  describe 'ファクトリ' do
    it '有効なファクトリを持つこと' do
      menu = build(:menu)
      expect(menu).to be_valid
    end
  end

  describe 'スコープ' do
    describe '.available' do
      it '販売可能なメニューのみを返すこと' do
        available_menu = create(:menu, is_available: true)
        unavailable_menu = create(:menu, is_available: false)

        expect(Menu.available).to include(available_menu)
        expect(Menu.available).not_to include(unavailable_menu)
      end
    end

    describe '.by_category' do
      it '指定したカテゴリのメニューのみを返すこと' do
        main_menu = create(:menu, category: 'メイン')
        dessert_menu = create(:menu, category: 'デザート')

        expect(Menu.by_category('メイン')).to include(main_menu)
        expect(Menu.by_category('メイン')).not_to include(dessert_menu)
      end
    end
  end
end
