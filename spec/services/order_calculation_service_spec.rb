require 'rails_helper'

RSpec.describe OrderCalculationService do
  describe '金額計算' do
    let(:menu1) { create(:menu, price: 1000) }
    let(:menu2) { create(:menu, price: 500) }

    let(:items_with_menus) do
      [
        { menu: menu1, quantity: 2 },
        { menu: menu2, quantity: 1 }
      ]
    end

    subject(:calculator) { described_class.new(items_with_menus) }

    describe '#subtotal' do
      it '小計を正しく計算すること' do
        expect(calculator.subtotal).to eq(2500)
      end
    end

    describe '#tax_amount' do
      it '税額を正しく計算すること（切り捨て）' do
        expect(calculator.tax_amount).to eq(250)
      end

      it '端数を切り捨てること' do
        menu = create(:menu, price: 333)
        items = [ { menu: menu, quantity: 1 } ]
        calc = described_class.new(items)

        expect(calc.tax_amount).to eq(33)
      end
    end

    describe '#total_amount' do
      it '合計金額を正しく計算すること' do
        expect(calculator.total_amount).to eq(2750)
      end
    end

    describe '#item_subtotal' do
      it '個別アイテムの小計を計算すること' do
        expect(calculator.item_subtotal(menu1, 3)).to eq(3000)
        expect(calculator.item_subtotal(menu2, 2)).to eq(1000)
      end
    end
  end
end
