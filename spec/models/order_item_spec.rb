require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  describe 'バリデーション' do
    it { should validate_presence_of(:menu_snapshot) }
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { should validate_presence_of(:subtotal) }
    it { should validate_numericality_of(:subtotal).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'リレーション' do
    it { should belong_to(:order) }
  end

  describe 'ファクトリ' do
    it '有効なファクトリを持つこと' do
      expect(build(:order_item)).to be_valid
    end
  end

  describe 'スナップショットヘルパーメソッド' do
    let(:order_item) do
      create(:order_item,
        menu_snapshot: {
          'id' => 1,
          'name' => 'ハンバーグ',
          'price' => 1200,
          'category' => 'メイン'
        }
      )
    end

    it 'menu_nameでスナップショットから名前を取得できること' do
      expect(order_item.menu_name).to eq('ハンバーグ')
    end

    it 'menu_priceでスナップショットsubから価格を取得できること' do
      expect(order_item.menu_price).to eq(1200)
    end

    it 'menu_idでスナップショットからIDを取得できること' do
      expect(order_item.menu_id).to eq(1)
    end
  end
end
