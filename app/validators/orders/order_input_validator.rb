module Orders
  class OrderInputValidator
    VALID_ORDER_TYPES = %w[dine_in takeout delivery].freeze

    attr_reader :errors

    def initialize(table_number:, items:, order_type:)
      @table_number = table_number
      @items = items
      @order_type = order_type
      @errors = []
      @menus_cache = {}
    end

    def validate!
      validate_items!
      validate_order_type!
      load_and_validate_menus!

      {
        menus_cache: @menus_cache,
        errors: @errors
      }
    end

    private

    def validate_items!
      return if @items.present?

      @errors << "注文アイテムが指定されていません"
      raise ActiveRecord::RecordInvalid.new
    end

    def validate_order_type!
      return if VALID_ORDER_TYPES.include?(@order_type)

      @errors << "order_typeは#{VALID_ORDER_TYPES.join(', ')}のいずれかである必要があります"
      raise ActiveRecord::RecordInvalid.new
    end

    def load_and_validate_menus!
      @items.each do |item_data|
        load_and_validate_menu(item_data[:menu_id])
      end
    end

    def load_and_validate_menu(menu_id)
      menu = Menu.lock.find(menu_id)
      validate_menu_availability!(menu)
      @menus_cache[menu_id] = menu
    rescue ActiveRecord::RecordNotFound
      @errors << "メニューID #{menu_id} が見つかりません"
      raise ActiveRecord::RecordInvalid.new
    end

    def validate_menu_availability!(menu)
      return if menu.is_available

      @errors << "#{menu.name}は現在注文できません"
      raise ActiveRecord::RecordInvalid.new
    end
  end
end
