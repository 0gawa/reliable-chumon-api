module Orders
  class IdempotencyChecker
    def initialize(idempotency_key)
      @idempotency_key = idempotency_key
    end

    def duplicate_exists?
      @idempotency_key.present? && existing_order.present?
    end

    def existing_order
      @existing_order ||= Order.find_by(idempotency_key: @idempotency_key)
    end

    def params_match?(params)
      return false unless existing_order

      # パラメータの比較ロジック
      # ここでは単純化のためにテーブル番号と注文タイプ、アイテム数を比較
      # 本番環境ではより厳密な比較が必要（アイテムの内容など）
      existing_order.table_number == params[:table_number] &&
        existing_order.order_type == (params[:order_type] || "dine_in") &&
        existing_order.order_items.count == params[:items].size
    end
  end
end
