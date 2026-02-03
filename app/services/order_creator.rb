class OrderCreator
  attr_reader :order, :errors

  def initialize(table_number:, items:, order_type: 'dine_in', idempotency_key: nil)
    @table_number = table_number
    @items = items
    @order_type = order_type
    @idempotency_key = idempotency_key
    @errors = []
    @menus_cache = {}
    @is_duplicate = false
  end

  def call
    return handle_duplicate if duplicate_order_exists?
    
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

  private

  def duplicate_order_exists?
    @idempotency_key.present? && existing_order
  end

  def existing_order
    @existing_order ||= Order.find_by(idempotency_key: @idempotency_key)
  end

  def handle_duplicate
    @order = existing_order
    @is_duplicate = true
    @order
  end

  def handle_deadlock
    @errors << 'Transaction deadlock detected. Please retry your request.'
  end

  def create_order
    validate_and_cache_menus
    build_order_with_items
    @order.save!
    @order
  rescue ActiveRecord::RecordInvalid => e
    @errors.concat(@order.errors.full_messages) if @order
    raise
  end

  def validate_and_cache_menus
    validator = Orders::OrderInputValidator.new(
      table_number: @table_number,
      items: @items,
      order_type: @order_type
    )
    
    validation_result = validator.validate!
    @menus_cache = validation_result[:menus_cache]
  rescue ActiveRecord::RecordInvalid
    @errors = validator.errors
    raise
  end

  def build_order_with_items
    calculator = OrderCalculationService.new(items_with_menus)
    
    @order = Order.new(
      table_number: @table_number,
      order_type: @order_type,
      total_amount: calculator.total_amount,
      tax_amount: calculator.tax_amount,
      status: 'pending',
      ordered_at: Time.current,
      idempotency_key: @idempotency_key
    )
    
    build_order_items(calculator)
  end

  def items_with_menus
    @items.map do |item_data|
      {
        menu: @menus_cache[item_data[:menu_id]],
        quantity: item_data[:quantity]
      }
    end
  end

  def build_order_items(calculator)
    items_with_menus.each do |item|
      @order.order_items.build(
        menu_snapshot: menu_snapshot_for(item[:menu]),
        quantity: item[:quantity],
        subtotal: calculator.item_subtotal(item[:menu], item[:quantity])
      )
    end
  end

  def menu_snapshot_for(menu)
    {
      'id' => menu.id,
      'name' => menu.name,
      'price' => menu.price,
      'category' => menu.category
    }
  end
end
