require 'rails_helper'

RSpec.describe MenuDailyStat, type: :model do
  describe 'associations' do
    it { should belong_to(:menu) }
  end

  describe 'validations' do
    it { should validate_presence_of(:aggregation_date) }
    it { should validate_presence_of(:total_quantity) }
    it { should validate_presence_of(:total_sales_amount) }
    it { should validate_numericality_of(:total_quantity).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:total_sales_amount).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:menu1) { create(:menu) }
    let!(:menu2) { create(:menu) }
    let!(:stat1) { create(:menu_daily_stat, menu: menu1, aggregation_date: Date.new(2026, 2, 1)) }
    let!(:stat2) { create(:menu_daily_stat, menu: menu2, aggregation_date: Date.new(2026, 2, 2)) }
    let!(:stat3) { create(:menu_daily_stat, menu: menu1, aggregation_date: Date.new(2026, 2, 3)) }

    describe '.by_date_range' do
      it '指定期間の統計を返すこと' do
        result = MenuDailyStat.by_date_range(Date.new(2026, 2, 1), Date.new(2026, 2, 2))
        expect(result).to include(stat1, stat2)
        expect(result).not_to include(stat3)
      end
    end

    describe '.by_menu' do
      it '指定メニューの統計を返すこと' do
        result = MenuDailyStat.by_menu(menu1.id)
        expect(result).to include(stat1, stat3)
        expect(result).not_to include(stat2)
      end
    end

    describe '.ordered_by_date' do
      it '日付降順でソートされること' do
        result = MenuDailyStat.ordered_by_date
        expect(result.first).to eq(stat3)
        expect(result.last).to eq(stat1)
      end
    end
  end
end
