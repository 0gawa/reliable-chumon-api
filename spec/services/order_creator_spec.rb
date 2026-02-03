require 'rails_helper'

RSpec.describe OrderCreator do
  let(:menu1) { create(:menu, name: 'ハンバーグ', price: 1000) }
  let(:menu2) { create(:menu, name: 'サラダ', price: 500) }

  describe '#call' do
    context '有効なパラメータの場合' do
      let(:items) do
        [
          { menu_id: menu1.id, quantity: 2 },
          { menu_id: menu2.id, quantity: 1 }
        ]
      end

      it '注文が作成されること' do
        creator = OrderCreator.new(table_number: 'A-1', items: items)

        expect {
          creator.call
        }.to change(Order, :count).by(1)
         .and change(OrderItem, :count).by(2)
      end

      it '正しい金額が計算されること' do
        creator = OrderCreator.new(table_number: 'A-1', items: items)
        order = creator.call

        # 小計: 1000*2 + 500*1 = 2500
        # 消費税: floor(2500 * 0.10) = 250
        # 合計: 2500 + 250 = 2750
        expect(order.total_amount).to eq(2750)
        expect(order.tax_amount).to eq(250)
      end

      it 'メニュースナップショットが正しく保存されること' do
        creator = OrderCreator.new(table_number: 'A-1', items: items)
        order = creator.call

        first_item = order.order_items.first
        expect(first_item.menu_snapshot['name']).to eq('ハンバーグ')
        expect(first_item.menu_snapshot['price']).to eq(1000)
        expect(first_item.menu_snapshot['id']).to eq(menu1.id)
      end

      it '小計が正しく計算されること' do
        creator = OrderCreator.new(table_number: 'A-1', items: items)
        order = creator.call

        first_item = order.order_items.first
        expect(first_item.subtotal).to eq(2000)  # 1000 * 2
      end

      it 'success?がtrueを返すこと' do
        creator = OrderCreator.new(table_number: 'A-1', items: items)
        creator.call

        expect(creator.success?).to be true
      end
    end

    context '販売不可のメニューが含まれる場合' do
      let(:unavailable_menu) { create(:menu, is_available: false) }
      let(:items) do
        [ { menu_id: unavailable_menu.id, quantity: 1 } ]
      end

      it '注文が作成されないこと' do
        creator = OrderCreator.new(table_number: 'A-1', items: items)

        expect {
          creator.call
        }.not_to change(Order, :count)
      end

      it 'エラーメッセージが設定されること' do
        creator = OrderCreator.new(table_number: 'A-1', items: items)
        creator.call

        expect(creator.errors).not_to be_empty
        expect(creator.errors.first).to include('現在注文できません')
      end

      it 'success?がfalseを返すこと' do
        creator = OrderCreator.new(table_number: 'A-1', items: items)
        creator.call

        expect(creator.success?).to be false
      end
    end

    context '注文アイテムが空の場合' do
      it '注文が作成されないこと' do
        creator = OrderCreator.new(table_number: 'A-1', items: [])

        expect {
          creator.call
        }.not_to change(Order, :count)
      end

      it 'エラーメッセージが設定されること' do
        creator = OrderCreator.new(table_number: 'A-1', items: [])
        creator.call

        expect(creator.errors).to include('注文アイテムが指定されていません')
      end
    end

    context '存在しないメニューIDが指定された場合' do
      it '注文が作成されず、エラーメッセージが設定されること' do
        creator = OrderCreator.new(
          table_number: 'A-1',
          items: [ { menu_id: 99999, quantity: 1 } ]
        )

        result = creator.call

        expect(result).to be_nil
        expect(creator.success?).to be false
        expect(creator.errors).not_to be_empty
      end
    end
  end

  describe '税額計算' do
    it '端数が正しく切り捨てられること' do
      menu = create(:menu, price: 333)
      items = [ { menu_id: menu.id, quantity: 1 } ]

      creator = OrderCreator.new(table_number: 'A-1', items: items)
      order = creator.call

      # 333 * 0.10 = 33.3 → floor = 33
      expect(order.tax_amount).to eq(33)
      expect(order.total_amount).to eq(366)  # 333 + 33
    end
  end
end
