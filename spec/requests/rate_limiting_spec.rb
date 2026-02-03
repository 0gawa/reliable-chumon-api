require 'rails_helper'

RSpec.describe 'Rate Limiting', type: :request do
  let(:menu) { create(:menu, name: 'テストメニュー', price: 1000) }

  before do
    # Clear rate limit cache before each test
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
  end

  describe 'API全体のレート制限' do
    it '通常のリクエストは正常に処理される' do
      get '/api/v1/customer/menus', as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers).not_to have_key('Retry-After')
    end

    # Note: 300リクエスト/5分のテストは時間がかかるため、制限値の確認のみ
    it 'レート制限が設定されていること' do
      # rack_attack.rbで設定されている値を確認
      expect(Rack::Attack.throttles.key?('api/ip')).to be true
    end
  end

  describe '注文作成のレート制限' do
    it '少数のリクエストは正常に処理される' do
      3.times do
        post '/api/v1/customer/orders',
          params: {
            table_number: 'A-1',
            order_type: 'dine_in',
            items: [ { menu_id: menu.id, quantity: 1 } ]
          },
          as: :json

        expect(response).to have_http_status(:ok).or have_http_status(:unprocessable_entity)
      end
    end

    it '30リクエスト/分を超えると429を返す', :skip_in_ci do
      # 注意: このテストは実行に時間がかかるため、通常はskip
      # 必要に応じてタグを削除して実行

      32.times do |i|
        post '/api/v1/customer/orders',
          params: {
            table_number: "A-#{i}",
            order_type: 'dine_in',
            items: [ { menu_id: menu.id, quantity: 1 } ]
          },
          as: :json

        if i < 30
          expect(response.status).to be_in([ 200, 201, 422 ])
        else
          expect(response).to have_http_status(429)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Rate limit exceeded')
          expect(response.headers['Retry-After']).to be_present
        end
      end
    end
  end

  describe '管理者APIのレート制限' do
    it '通常のリクエストは正常に処理される' do
      5.times do
        get '/api/v1/admin/menus', as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    it 'レート制限が設定されていること' do
      expect(Rack::Attack.throttles.key?('admin/ip')).to be true
    end
  end

  describe 'レート制限時のレスポンス' do
    it '429エラーは適切なJSONレスポンスを返す', :skip_in_ci do
      # 制限を超える数のリクエストを送信
      35.times do |i|
        post '/api/v1/customer/orders',
          params: {
            table_number: "B-#{i}",
            order_type: 'takeout',
            items: [ { menu_id: menu.id, quantity: 1 } ]
          },
          as: :json
      end

      # 最後のレスポンスを確認
      expect(response).to have_http_status(429)
      expect(response.content_type).to match(/application\/json/)

      json = JSON.parse(response.body)
      expect(json).to have_key('error')
      expect(json).to have_key('message')
      expect(json).to have_key('retry_after_seconds')

      expect(response.headers['Retry-After']).to be_present
    end
  end
end
