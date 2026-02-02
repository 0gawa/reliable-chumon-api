class DailyStatsAggregator
  def initialize(target_date = Date.current)
    @target_date = target_date
  end

  def aggregate
    aggregated_data = build_aggregated_data
    upsert_stats(aggregated_data)
  end

  private

  def build_aggregated_data
    OrderItem.joins(:order)
             .where(orders: { status: 'completed' })
             .where('DATE(orders.ordered_at) = ?', @target_date)
             .group("(menu_snapshot->>'id')::integer")
             .select(
               "(menu_snapshot->>'id')::integer AS menu_id",
               'SUM(quantity) AS total_quantity',
               'SUM(subtotal) AS total_sales_amount'
             )
             .map do |result|
      {
        menu_id: result[:menu_id].to_i,
        aggregation_date: @target_date,
        total_quantity: result[:total_quantity].to_i,
        total_sales_amount: result[:total_sales_amount].to_i
      }
    end
  end

  def upsert_stats(aggregated_data)
    return if aggregated_data.empty?

    MenuDailyStat.upsert_all(
      aggregated_data,
      unique_by: [:menu_id, :aggregation_date]
    )
  end
end
