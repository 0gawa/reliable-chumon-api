require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Orders', type: :request do
  describe 'GET /api/v1/admin/orders' do
    it '注文一覧を取得できること' do
      orders = create_list(:order, 3)

      get '/api/v1/admin/orders', as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.size).to be >= 3
    end
  end

  describe 'GET /api/v1/admin/orders/:id' do
    let!(:order) { create(:order, :no_items) }
    let!(:order_item) { create(:order_item, order: order) }

    it '注文詳細を取得できること' do
      get "/api/v1/admin/orders/#{order.id}", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(order.id)
      expect(json['table_number']).to eq(order.table_number)
      expect(json['order_items']).to be_an(Array)
      expect(json['order_items'].size).to eq(1)
    end
  end

  describe 'PATCH /api/v1/admin/orders/:id/update_status' do
    let!(:order) { create(:order, status: 'pending') }

    context '有効なステータスの場合' do
      it 'ステータスが更新されること' do
        patch "/api/v1/admin/orders/#{order.id}/update_status",
              params: { order: { status: 'confirmed' } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(order.reload.status).to eq('confirmed')
      end

      it 'pending → confirmed → completed の遷移ができること' do
        # pending → confirmed
        patch "/api/v1/admin/orders/#{order.id}/update_status",
              params: { order: { status: 'confirmed' } },
              as: :json
        expect(order.reload.status).to eq('confirmed')

        # confirmed → completed
        patch "/api/v1/admin/orders/#{order.id}/update_status",
              params: { order: { status: 'completed' } },
              as: :json
        expect(order.reload.status).to eq('completed')
      end
    end

    context '無効なステータスの場合' do
      it 'ステータスが更新されないこと' do
        patch "/api/v1/admin/orders/#{order.id}/update_status",
              params: { order: { status: 'invalid_status' } },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(order.reload.status).to eq('pending')
      end
    end

    context 'エッジケース' do
      it '存在しない注文IDで404エラーが返されること' do
        patch "/api/v1/admin/orders/99999/update_status",
              params: { order: { status: 'confirmed' } },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
