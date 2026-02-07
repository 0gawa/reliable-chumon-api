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
             headers: { 'X-Idempotency-Key' => valid_uuid },
             as: :json

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to be_present

        order = Order.find(json_response['id'])
        expect(order.idempotency_key).to eq(valid_uuid)
      end
    end

    context '重複リクエストの場合' do
      it '同じ冪等性キーで2回リクエストすると、2回目は既存の注文を返す' do
        post '/api/v1/customer/orders',
             params: order_params,
             headers: { 'X-Idempotency-Key' => valid_uuid },
             as: :json

        expect(response).to have_http_status(:created)
        first_response = JSON.parse(response.body)
        first_order_id = first_response['id']

        post '/api/v1/customer/orders',
             params: order_params,
             headers: { 'X-Idempotency-Key' => valid_uuid },
             as: :json

        expect(response).to have_http_status(:ok)
        second_response = JSON.parse(response.body)

        expect(second_response['id']).to eq(first_order_id)
        expect(Order.where(idempotency_key: valid_uuid).count).to eq(1)
      end
    end

    context '冪等性キーなしの場合' do
      it '通常通り注文が作成される' do
        post '/api/v1/customer/orders', params: order_params, as: :json

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        order = Order.find(json_response['id'])
        expect(order.idempotency_key).to be_nil
      end

      it '複数回リクエストすると複数の注文が作成される' do
        expect {
          2.times { post '/api/v1/customer/orders', params: order_params, as: :json }
        }.to change(Order, :count).by(2)
      end
    end

    context '異なるパラメータで同じ冪等性キーを使用した場合' do
      it '422 Unprocessable Entityを返す（またはポリシーにより409 Conflict）' do
        # 1回目のリクエスト（成功）
        post '/api/v1/customer/orders',
             params: order_params,
             headers: { 'X-Idempotency-Key' => valid_uuid },
             as: :json
        expect(response).to have_http_status(:created)

        # 2回目のリクエスト（異なるパラメータ）
        different_params = order_params.deep_dup
        different_params[:order][:table_number] = 'B-2'

        post '/api/v1/customer/orders',
             params: different_params,
             headers: { 'X-Idempotency-Key' => valid_uuid },
             as: :json

        # 実装によっては409 Conflictや422 Unprocessable Entityを返す
        expect(response.status).to be_in([409, 422])
        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('IDEMPOTENCY_KEY_MISMATCH')
      end
    end

    context '無効なUUID形式' do
      it 'UUID v4形式でない場合は注文作成に失敗する' do
        invalid_uuid = 'not-a-valid-uuid'

        expect {
          post '/api/v1/customer/orders',
               params: order_params,
               headers: { 'X-Idempotency-Key' => invalid_uuid },
               as: :json
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('VALIDATION_ERROR')
      end
    end
  end
end
