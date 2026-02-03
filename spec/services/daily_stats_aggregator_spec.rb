require 'rails_helper'

RSpec.describe DailyStatsAggregator do
  let(:menu1) { create(:menu, name: 'ハンバーグ', price: 1000) }
  let(:menu2) { create(:menu, name: 'サラダ', price: 500) }
  let(:target_date) { Date.new(2026, 2, 1) }

  describe '#aggregate' do
    context '完了注文が存在する場合' do
      before do
        order1 = create(:order, :completed, :no_items, ordered_at: target_date.to_time)
        create(:order_item, order: order1, menu_snapshot: { 'id' => menu1.id }, quantity: 2, subtotal: 2000)
        create(:order_item, order: order1, menu_snapshot: { 'id' => menu2.id }, quantity: 1, subtotal: 500)

        order2 = create(:order, :completed, :no_items, ordered_at: target_date.to_time + 2.hours)
        create(:order_item, order: order2, menu_snapshot: { 'id' => menu1.id }, quantity: 3, subtotal: 3000)
      end

      it '日次統計が正しく集計されること' do
        aggregator = DailyStatsAggregator.new(target_date)
        aggregator.aggregate

        stat1 = MenuDailyStat.find_by(menu_id: menu1.id, aggregation_date: target_date)
        expect(stat1.total_quantity).to eq(5)
        expect(stat1.total_sales_amount).to eq(5000)

        stat2 = MenuDailyStat.find_by(menu_id: menu2.id, aggregation_date: target_date)
        expect(stat2.total_quantity).to eq(1)
        expect(stat2.total_sales_amount).to eq(500)
      end
    end

    context '重複実行された場合' do
      before do
        order = create(:order, :completed, :no_items, ordered_at: target_date.to_time)
        create(:order_item, order: order, menu_snapshot: { 'id' => menu1.id }, quantity: 2, subtotal: 2000)
      end

      it '同じデータで上書きされること' do
        aggregator = DailyStatsAggregator.new(target_date)

        aggregator.aggregate
        aggregator.aggregate

        stat = MenuDailyStat.find_by(menu_id: menu1.id, aggregation_date: target_date)
        expect(stat.total_quantity).to eq(2)
        expect(stat.total_sales_amount).to eq(2000)
      end
    end

    context '対象日に注文がない場合' do
      it '統計が作成されないこと' do
        aggregator = DailyStatsAggregator.new(target_date)
        aggregator.aggregate

        expect(MenuDailyStat.count).to eq(0)
      end
    end

    context 'pending状態の注文は含まれない' do
      before do
        order = create(:order, status: 'pending', ordered_at: target_date.to_time)
        create(:order_item, order: order, menu_snapshot: { 'id' => menu1.id }, quantity: 2, subtotal: 2000)
      end

      it '統計に含まれないこと' do
        aggregator = DailyStatsAggregator.new(target_date)
        aggregator.aggregate

        expect(MenuDailyStat.count).to eq(0)
      end
    end

    context 'エッジケース: confirmed状態の注文（ペアワイズ法）' do
      before do
        order = create(:order, status: 'confirmed', ordered_at: target_date.to_time)
        create(:order_item, order: order, menu_snapshot: { 'id' => menu1.id }, quantity: 2, subtotal: 2000)
      end

      it 'confirmed状態は集計されないこと' do
        aggregator = DailyStatsAggregator.new(target_date)
        aggregator.aggregate

        expect(MenuDailyStat.count).to eq(0)
      end
    end

    context 'エッジケース: 日付境界のテスト' do
      before do
        # 23:59:59の注文
        order1 = create(:order, :completed, :no_items, ordered_at: target_date.to_time + 23.hours + 59.minutes + 59.seconds)
        create(:order_item, order: order1, menu_snapshot: { 'id' => menu1.id }, quantity: 1, subtotal: 1000)

        # 00:00:00の注文（翌日）
        next_day = target_date + 1.day
        order2 = create(:order, :completed, :no_items, ordered_at: next_day.to_time)
        create(:order_item, order: order2, menu_snapshot: { 'id' => menu1.id }, quantity: 2, subtotal: 2000)
      end

      it '日付境界で正しく分かれること' do
        aggregator = DailyStatsAggregator.new(target_date)
        aggregator.aggregate

        stat = MenuDailyStat.find_by(menu_id: menu1.id, aggregation_date: target_date)
        expect(stat.total_quantity).to eq(1)  # 23:59:59の注文のみ
        expect(stat.total_sales_amount).to eq(1000)
      end
    end
  end
end
