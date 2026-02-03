require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Menus', type: :request do
  describe 'GET /api/v1/admin/menus' do
    it 'メニュー一覧を取得できること' do
      menus = create_list(:menu, 3)

      get '/api/v1/admin/menus', as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.size).to be >= 3
      menu_ids = json.map { |m| m['id'] }
      menus.each do |menu|
        expect(menu_ids).to include(menu.id)
      end
    end
  end

  describe 'GET /api/v1/admin/menus/:id' do
    let(:menu) { create(:menu) }

    it 'メニュー詳細を取得できること' do
      get "/api/v1/admin/menus/#{menu.id}", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(menu.id)
      expect(json['name']).to eq(menu.name)
    end
  end

  describe 'POST /api/v1/admin/menus' do
    context '有効なパラメータの場合' do
      let(:valid_params) do
        { menu: { name: 'ハンバーグ', price: 1000, category: 'メイン' } }
      end

      it 'メニューが作成されること' do
        expect {
          post '/api/v1/admin/menus', params: valid_params, as: :json
        }.to change(Menu, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('ハンバーグ')
        expect(json['price']).to eq(1000)
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        { menu: { name: '', price: -100 } }
      end

      it 'メニューが作成されないこと' do
        expect {
          post '/api/v1/admin/menus', params: invalid_params, as: :json
        }.not_to change(Menu, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']). to have_key('code')
        expect(json['error']['code']).to eq('VALIDATION_ERROR')
      end
    end
  end

  describe 'PATCH /api/v1/admin/menus/:id' do
    let(:menu) { create(:menu, name: '元の名前') }

    context '有効なパラメータの場合' do
      it 'メニューが更新されること' do
        patch "/api/v1/admin/menus/#{menu.id}", params: { menu: { name: '新しい名前' } }, as: :json

        expect(response).to have_http_status(:ok)
        expect(menu.reload.name).to eq('新しい名前')
      end

      it 'is_availableフラグを切り替えられること' do
        patch "/api/v1/admin/menus/#{menu.id}", params: { menu: { is_available: false } }, as: :json

        expect(response).to have_http_status(:ok)
        expect(menu.reload.is_available).to be false
      end
    end

    context '無効なパラメータの場合' do
      it 'メニューが更新されないこと' do
        patch "/api/v1/admin/menus/#{menu.id}", params: { menu: { price: -100 } }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/admin/menus/:id' do
    let!(:menu) { create(:menu) }

    it 'メニューが削除されること' do
      expect {
        delete "/api/v1/admin/menus/#{menu.id}", as: :json
      }.to change(Menu, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
