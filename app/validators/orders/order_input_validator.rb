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
      if @items.blank?
        @errors << '注文アイテムが指定されていません'
        raise ActiveRecord::RecordInvalid.new
      end
    end

    def validate_order_type!
      unless VALID_ORDER_TYPES.include?(@order_type)
        @errors << "order_typeは#{VALID_ORDER_TYPES.join(', ')}のいずれかである必要があります"
        raise ActiveRecord::RecordInvalid.new
      end
    end

    def load_and_validate_menus!
      @items.each do |item_data|
        menu_id = item_data[:menu_id]
        
        begin
          # 悲観的ロック: トランザクション中のデータ整合性を保証
          # 将来の在庫管理機能で重要になる
          menu = Menu.lock.find(menu_id)
          validate_menu_availability!(menu)
          @menus_cache[menu_id] = menu
        rescue ActiveRecord::RecordNotFound
          @errors << "メニューID #{menu_id} が見つかりません"
          raise ActiveRecord::RecordInvalid.new
        end
      end
    end

    def validate_menu_availability!(menu)
      unless menu.is_available
        @errors << "#{menu.name}は現在注文できません"
        raise ActiveRecord::RecordInvalid.new
      end
    end
  end
end
