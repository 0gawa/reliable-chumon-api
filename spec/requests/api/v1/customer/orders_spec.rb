require 'rails_helper'

RSpec.describe 'Api::V1::Customer::Orders', type: :request do
  let(:menu1) { create(:menu, name: 'ハンバーグ', price: 1000, is_available: true) }
  let(:menu2) { create(:menu, name: 'サラダ', price: 500, is_available: true) }

  describe 'POST /api/v1/customer/orders' do
    context '正常系' do
      let(:valid_params) do
        {
          order: {
            table_number: 'A-1',
            items: [
              { menu_id: menu1.id, quantity: 2 },
              { menu_id: menu2.id, quantity: 1 }
            ]
          }
        }
      end

      it '注文が作成されること' do
        expect {
          post '/api/v1/customer/orders', params: valid_params, as: :json
        }.to change(Order, :count).by(1)
         .and change(OrderItem, :count).by(2)

        expect(response).to have_http_status(:created)
      end

      it '正しい金額が計算されること' do
        post '/api/v1/customer/orders', params: valid_params, as: :json

        json = JSON.parse(response.body)
        # 小計: 1000*2 + 500*1 = 2500
        # 消費税: floor(2500 * 0.10) = 250
        # 合計: 2500 + 250 = 2750
        expect(json['total_amount']).to eq(2750)
        expect(json['tax_amount']).to eq(250)
      end

      it 'メニュースナップショットが保存されること' do
        post '/api/v1/customer/orders', params: valid_params, as: :json

        json = JSON.parse(response.body)
        first_item = json['order_items'].first
        expect(first_item['menu_snapshot']['name']).to eq('ハンバーグ')
        expect(first_item['menu_snapshot']['price']).to eq(1000)
      end

      it 'table_numberがnilでも注文が作成されること（テイクアウト・デリバリー）' do
        params = {
          order: {
            table_number: nil,
            items: [
              { menu_id: menu1.id, quantity: 1 }
            ]
          }
        }

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.to change(Order, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['table_number']).to be_nil
      end

      it 'order_typeを指定しない場合、デフォルト値dine_inになること' do
        post '/api/v1/customer/orders', params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['order_type']).to eq('dine_in')
      end

      it 'order_type=takeoutで注文が作成されること' do
        params = valid_params.deep_merge(order: { order_type: 'takeout' })

        post '/api/v1/customer/orders', params: params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['order_type']).to eq('takeout')
      end

      it 'order_type=deliveryで注文が作成されること' do
        params = valid_params.deep_merge(order: { order_type: 'delivery' })

        post '/api/v1/customer/orders', params: params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['order_type']).to eq('delivery')
      end
    end

    context 'エッジケース: order_typeバリデーション' do
      let(:valid_params) do
        {
          order: {
            table_number: 'A-1',
            items: [
              { menu_id: menu1.id, quantity: 2 },
              { menu_id: menu2.id, quantity: 1 }
            ]
          }
        }
      end

      it '不正なorder_typeで422エラーが返されること' do
        params = valid_params.deep_merge(order: { order_type: 'invalid_type' })

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'エッジケース: 販売不可メニュー' do
      it '販売不可メニューの注文で422エラーが返されること' do
        unavailable_menu = create(:menu, is_available: false)

        params = {
          order: {
            table_number: 'A-1',
            items: [ { menu_id: unavailable_menu.id, quantity: 1 } ]
          }
        }

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('VALIDATION_ERROR')
        expect(json['error']['details']['errors'].first).to include('現在注文できません')
      end
    end

    context 'エッジケース: 数量バリデーション' do
      it '数量0の注文で422エラーが返されること' do
        params = {
          order: {
            table_number: 'A-1',
            items: [ { menu_id: menu1.id, quantity: 0 } ]
          }
        }

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it '数量が負数の注文で422エラーが返されること' do
        params = {
          order: {
            table_number: 'A-1',
            items: [ { menu_id: menu1.id, quantity: -1 } ]
          }
        }

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'エッジケース: 存在しないメニュー' do
      it '存在しないmenu_idで422エラーが返されること' do
        params = {
          order: {
            table_number: 'A-1',
            items: [ { menu_id: 99999, quantity: 1 } ]
          }
        }

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('VALIDATION_ERROR')
        expect(json['error']['details']['errors']).not_to be_empty
      end
    end

    context 'エッジケース: テーブル番号バリデーション' do
      it '空文字列のテーブル番号も許可されること' do
        params = {
          order: {
            table_number: '',
            items: [ { menu_id: menu1.id, quantity: 1 } ]
          }
        }

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.to change(Order, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it '長すぎるテーブル番号(11文字以上)で422エラーが返されること' do
        params = {
          order: {
            table_number: 'A' * 11,  # 11文字
            items: [ { menu_id: menu1.id, quantity: 1 } ]
          }
        }

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'エッジケース: 注文アイテム' do
      it '空の注文アイテムで422エラーが返されること' do
        params = {
          order: {
            table_number: 'A-1',
            items: []
          }
        }

        expect {
          post '/api/v1/customer/orders', params: params, as: :json
        }.not_to change(Order, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('VALIDATION_ERROR')
        expect(json['error']['details']['errors']).to include('注文アイテムが指定されていません')
      end
    end

    context 'エッジケース: 大量注文' do
      it '大量の数量(1000個)でも正しく処理されること' do
        params = {
          order: {
            table_number: 'A-1',
            items: [ { menu_id: menu1.id, quantity: 1000 } ]
          }
        }

        post '/api/v1/customer/orders', params: params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        # 1000 * 1000 = 1,000,000
        # 税: 100,000
        # 合計: 1,100,000
        expect(json['total_amount']).to eq(1_100_000)
      end
    end
  end

  describe 'GET /api/v1/customer/orders/:id/summary' do
    context '正常系' do
      let!(:order) { create(:order, :no_items) }
      let!(:order_item) { create(:order_item, order: order) }

      it '注文サマリーが取得できること' do
        get "/api/v1/customer/orders/#{order.id}/summary", as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(order.id)
        expect(json['table_number']).to eq(order.table_number)
        expect(json['total_amount']).to eq(order.total_amount)
        expect(json['order_items']).to be_an(Array)
      end
    end

    context 'エッジケース' do
      it '存在しない注文IDで404エラーが返されること' do
        get '/api/v1/customer/orders/99999/summary', as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('NOT_FOUND')
        expect(json['error']['status']).to eq(404)
      end
    end
  end
end
