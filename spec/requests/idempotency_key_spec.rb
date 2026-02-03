require 'rails_helper'

RSpec.describe '冪等性キー (Idempotency Key)', type: :request do
  let(:menu) { create(:menu, name: 'Test Menu', price: 1000, is_available: true) }
  let(:valid_uuid) { SecureRandom.uuid }
  
  let(:order_params) do
    {
      order: {
        table_number: 'A-1',
        order_type: 'dine_in',
        items: [
          { menu_id: menu.id, quantity: 2 }
        ]
      }
    }
  end
  
  describe 'POST /api/v1/customer/orders with X-Idempotency-Key' do
    context '新規注文の場合' do
      it '冪等性キーありで注文が作成される' do
        post '/api/v1/customer/orders', 
             params: order_params,
             headers: { 'X-Idempotency-Key' => valid_uuid }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to be_present
        
        # データベースに保存されていることを確認
        order = Order.find(json_response['id'])
        expect(order.idempotency_key).to eq(valid_uuid)
      end
    end
    
    context '重複リクエストの場合' do
      it '同じ冪等性キーで2回リクエストすると、2回目は既存の注文を返す' do
        # 1回目のリクエスト
        post '/api/v1/customer/orders', 
             params: order_params,
             headers: { 'X-Idempotency-Key' => valid_uuid }
        
        expect(response).to have_http_status(:created)
        first_response = JSON.parse(response.body)
        first_order_id = first_response['id']
        
        # 2回目の同じリクエスト
        post '/api/v1/customer/orders', 
             params: order_params,
             headers: { 'X-Idempotency-Key' => valid_uuid }
        
        expect(response).to have_http_status(:ok) # 201ではなく200
        second_response = JSON.parse(response.body)
        
        # 同じ注文IDが返される
        expect(second_response['id']).to eq(first_order_id)
        
        # 新しい注文は作成されていない
        expect(Order.where(idempotency_key: valid_uuid).count).to eq(1)
      end
    end
    
    context '冪等性キーなしの場合' do
      it '通常通り注文が作成される' do
        post '/api/v1/customer/orders', params: order_params
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        order = Order.find(json_response['id'])
        expect(order.idempotency_key).to be_nil
      end
      
      it '複数回リクエストすると複数の注文が作成される' do
        expect {
          2.times { post '/api/v1/customer/orders', params: order_params }
        }.to change(Order, :count).by(2)
      end
    end
    
    context '無効なUUID形式' do
      it 'UUID v4形式でない場合はエラーを返す' do
        invalid_uuid = 'not-a-valid-uuid'
        
        post '/api/v1/customer/orders', 
             params: order_params,
             headers: { 'X-Idempotency-Key' => invalid_uuid }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include(match(/UUID/i))
      end
    end
  end
end
