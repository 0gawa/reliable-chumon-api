class OrderCreator
  attr_reader :order, :errors

  def initialize(table_number:, items:, order_type: "dine_in", idempotency_key: nil)
    @table_number = table_number
    @items = items
    @order_type = order_type
    @idempotency_key = idempotency_key
    @errors = []
    @is_duplicate = false
  end

  def call
    return handle_duplicate if duplicate_exists?

    ActiveRecord::Base.transaction do
      create_order
    end
  rescue ActiveRecord::RecordInvalid
    nil
  rescue ActiveRecord::Deadlocked
    handle_deadlock
    nil
  end

  def success?
    @errors.empty? && @order&.persisted?
  end

  def duplicate?
    @is_duplicate
  end

  def idempotency_mismatch?
    @idempotency_mismatch
  end

  private

  def duplicate_exists?
    return false unless idempotency_checker.duplicate_exists?

    if idempotency_checker.params_match?(
      table_number: @table_number,
      order_type: @order_type,
      items: @items
    )
      true
    else
      @idempotency_mismatch = true
      false
    end
  end

  def idempotency_checker
    @idempotency_checker ||= Orders::IdempotencyChecker.new(@idempotency_key)
  end

  def handle_duplicate
    @order = idempotency_checker.existing_order
    @is_duplicate = true
    @order
  end

  def create_order
    menus_cache = validate_and_get_menus
    items_with_menus = build_items_with_menus(menus_cache)

    @order = order_builder(items_with_menus).build
    @order.save!
    @order
  rescue ActiveRecord::RecordInvalid => e
    @errors.concat(@order.errors.full_messages) if @order
    raise
  end

  def validate_and_get_menus
    validator = Orders::OrderInputValidator.new(
      table_number: @table_number,
      items: @items,
      order_type: @order_type
    )

    validation_result = validator.validate!
    validation_result[:menus_cache]
  rescue ActiveRecord::RecordInvalid
    @errors = validator.errors
    raise
  end

  def build_items_with_menus(menus_cache)
    @items.map do |item_data|
      {
        menu: menus_cache[item_data[:menu_id]],
        quantity: item_data[:quantity]
      }
    end
  end

  def order_builder(items_with_menus)
    Orders::OrderBuilder.new(
      table_number: @table_number,
      order_type: @order_type,
      items_with_menus: items_with_menus,
      idempotency_key: @idempotency_key
    )
  end

  def handle_deadlock
    @errors << "Transaction deadlock detected. Please retry your request."
  end
end
