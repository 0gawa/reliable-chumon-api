require 'rails_helper'

RSpec.describe '悲観的ロック (Pessimistic Locking)', type: :model do
  describe 'OrderCreator での悲観的ロック' do
    let(:menu) { create(:menu, name: 'Test Menu', price: 1000, is_available: true) }
    
    it 'メニュー読み取り時に SELECT FOR UPDATE が使用される', :skip_in_ci do
      # 実際のSQLログを確認するテスト
      items = [{ menu_id: menu.id, quantity: 2 }]
      
      # SQLログを監視
      queries = []
      ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('menus')
      end
      
      creator = OrderCreator.new(
        table_number: 'A-1',
        items: items,
        order_type: 'dine_in'
      )
      
      ActiveRecord::Base.transaction do
        creator.call
      end
      
      # FOR UPDATE句が含まれていることを確認
      menu_queries = queries.select { |q| q.include?('SELECT') && q.include?('menus') }
      expect(menu_queries.any? { |q| q.include?('FOR UPDATE') }).to be true
    end
    
    it 'トランザクション内でメニューデータが確実に読み取られる' do
      items = [{ menu_id: menu.id, quantity: 2 }]
      
      creator = OrderCreator.new(
        table_number: 'A-1',
        items: items,
        order_type: 'dine_in'
      )
      
      order = nil
      ActiveRecord::Base.transaction do
        order = creator.call
      end
      
      expect(creator.success?).to be true
      expect(order).to be_persisted
    end
  end
  
  describe 'デッドロック対応' do
    it '# デッドロックエラーを適切に処理する' do
      menu = create(:menu, name: 'Test Menu', price: 1000, is_available: true)
      items = [{ menu_id: menu.id, quantity: 2 }]
      
      creator = OrderCreator.new(
        table_number: 'A-1',
        items: items,
        order_type: 'dine_in'
      )
      
      # デッドロックをシミュレート
      allow(ActiveRecord::Base).to receive(:transaction).and_raise(ActiveRecord::Deadlocked.new)
      
      order = creator.call
      
      expect(order).to be_nil
      expect(creator.success?).to be false
      expect(creator.errors).to include(match(/deadlock/i))
    end
  end
end
