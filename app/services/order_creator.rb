class OrderCreator
  attr_reader :order, :errors

  def initialize(table_number:, items:, order_type: 'dine_in')
    @table_number = table_number
    @items = items
    @order_type = order_type
    @errors = []
    @menus_cache = {}
  end

  def call
    ActiveRecord::Base.transaction do
      create_order
    end
  rescue ActiveRecord::RecordInvalid => e
    # Errors are already set by the validator, don't overwrite them
    nil
  end

  def success?
    @errors.empty? && @order&.persisted?
  end

  private

  def create_order
    validator = Orders::OrderInputValidator.new(
      table_number: @table_number,
      items: @items,
      order_type: @order_type
    )
    
    begin
      validation_result = validator.validate!
      @menus_cache = validation_result[:menus_cache]
    rescue ActiveRecord::RecordInvalid
      # Get errors from validator instance even after exception
      @errors = validator.errors
      raise
    end
    
    calculator = OrderCalculationService.new(items_with_menus)
    
    @order = Order.new(
      table_number: @table_number,
      order_type: @order_type,
      total_amount: calculator.total_amount,
      tax_amount: calculator.tax_amount,
      status: 'pending',
      ordered_at: Time.current
    )
    
    build_order_items(calculator)
    @order.save!
    @order
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
        menu_snapshot: create_menu_snapshot(item[:menu]),
        quantity: item[:quantity],
        subtotal: calculator.item_subtotal(item[:menu], item[:quantity])
      )
    end
  end

  def create_menu_snapshot(menu)
    {
      'id' => menu.id,
      'name' => menu.name,
      'price' => menu.price,
      'category' => menu.category
    }
  end
end
