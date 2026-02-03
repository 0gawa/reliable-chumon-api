require 'rails_helper'

RSpec.describe 'Api::V1::Customer::Menus', type: :request do
  describe 'GET /api/v1/customer/menus' do
    context '正常系' do
      it '販売可能なメニュー一覧が取得できること' do
        available_menus = create_list(:menu, 3, is_available: true)
        unavailable_menu = create(:menu, is_available: false)

        get '/api/v1/customer/menus', as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        ids = json.map { |m| m['id'] }

        available_menus.each do |menu|
          expect(ids).to include(menu.id)
        end
        expect(ids).not_to include(unavailable_menu.id)
      end

      it '空配列が返されること（販売可能なメニューがない場合）' do
        Menu.where(is_available: true).delete_all
        create_list(:menu, 3, is_available: false)

        get '/api/v1/customer/menus', as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end

    context 'エッジケース' do
      it '販売不可メニューは一覧に表示されないこと' do
        available = create(:menu, name: '販売中', is_available: true)
        unavailable = create(:menu, name: '販売停止', is_available: false)

        get '/api/v1/customer/menus', as: :json

        json = JSON.parse(response.body)
        names = json.map { |m| m['name'] }

        expect(names).to include('販売中')
        expect(names).not_to include('販売停止')
      end
    end
  end

  describe 'GET /api/v1/customer/menus/:id' do
    context '正常系' do
      it '販売可能なメニュー詳細が取得できること' do
        menu = create(:menu, is_available: true)

        get "/api/v1/customer/menus/#{menu.id}", as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(menu.id)
        expect(json['name']).to eq(menu.name)
      end
    end

    context 'エッジケース' do
      it '存在しないメニューIDで404エラーが返されること' do
        get '/api/v1/customer/menus/99999', as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('メニューが見つかりません')
      end

      it '販売不可メニューの詳細取得で404エラーが返されること' do
        unavailable_menu = create(:menu, is_available: false)

        get "/api/v1/customer/menus/#{unavailable_menu.id}", as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('メニューが見つかりません')
      end
    end
  end
end
