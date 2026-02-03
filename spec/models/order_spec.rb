require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'バリデーション' do
    it { should_not validate_presence_of(:table_number) }
    it { should validate_length_of(:table_number).is_at_most(10) }
    it { should allow_value(nil).for(:table_number) }
    it { should validate_presence_of(:total_amount) }
    it { should validate_numericality_of(:total_amount).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:tax_amount) }
    it { should validate_numericality_of(:tax_amount).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[pending confirmed completed cancelled]) }
    it { should validate_presence_of(:ordered_at) }
    it { should validate_presence_of(:order_type) }
  end

  describe 'Enum' do
    it 'order_typeのenumが正しく定義されていること' do
      expect(Order.order_types).to eq({ 'dine_in' => 0, 'takeout' => 1, 'delivery' => 2 })
    end

    it 'enum経由でorder_typeを設定できること' do
      order = build(:order)
      expect(order.dine_in?).to be true

      order.order_type = :takeout
      expect(order.takeout?).to be true
      expect(order.order_type).to eq('takeout')
    end
  end

  describe 'リレーション' do
    it { should have_many(:order_items).dependent(:destroy) }
  end

  describe 'ファクトリ' do
    it '有効なファクトリを持つこと' do
      order = build(:order)
      expect(order).to be_valid
      expect(order.order_type).to eq('dine_in')  # デフォルト値
    end

    it 'traitsが正しく動作すること' do
      expect(build(:order, :confirmed).status).to eq('confirmed')
      expect(build(:order, :completed).status).to eq('completed')
      expect(build(:order, :cancelled).status).to eq('cancelled')
    end
  end

  describe 'スコープ' do
    let!(:table_a_order) { create(:order, table_number: 'A-1') }
    let!(:table_b_order) { create(:order, table_number: 'B-2') }
    let!(:pending_order) { create(:order, status: 'pending') }
    let!(:confirmed_order) { create(:order, :confirmed) }
    let!(:today_order) { create(:order, ordered_at: Time.current) }
    let!(:yesterday_order) { create(:order, ordered_at: 1.day.ago) }

    describe '.by_table' do
      it '指定したテーブル番号の注文のみを返すこと' do
        expect(Order.by_table('A-1')).to include(table_a_order)
        expect(Order.by_table('A-1')).not_to include(table_b_order)
      end
    end

    describe '.by_status' do
      it '指定したステータスの注文のみを返すこと' do
        expect(Order.by_status('pending')).to include(pending_order)
        expect(Order.by_status('pending')).not_to include(confirmed_order)
      end
    end

    describe '.pending' do
      it 'pending状態の注文のみを返すこと' do
        expect(Order.pending).to include(pending_order)
        expect(Order.pending).not_to include(confirmed_order)
      end
    end

    describe '.today' do
      it '今日の注文のみを返すこと' do
        expect(Order.today).to include(today_order)
        expect(Order.today).not_to include(yesterday_order)
      end
    end
  end
end
