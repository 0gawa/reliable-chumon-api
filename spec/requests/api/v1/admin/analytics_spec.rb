require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Analytics', type: :request do
  describe 'GET /api/v1/admin/analytics/daily' do
    let(:menu) { create(:menu, name: 'ハンバーグ') }
    
    before do
      create(:menu_daily_stat, 
        menu: menu,
        aggregation_date: Date.current,
        total_quantity: 10,
        total_sales_amount: 10000
      )
    end
    
    it 'デイリー統計が取得できること' do
      get '/api/v1/admin/analytics/daily', as: :json
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end
  end

  describe 'GET /api/v1/admin/analytics/summary' do
    let(:menu) { create(:menu, name: 'サラダ') }
    
    before do
      create(:menu_daily_stat,
        menu: menu,
        aggregation_date: Date.current,
        total_quantity: 5,
        total_sales_amount: 2500
      )
    end

    it 'サマリー情報が取得できること' do
      get '/api/v1/admin/analytics/summary', as: :json
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json).to have_key('total_sales_amount')
      expect(json).to have_key('total_quantity')
      expect(json).to have_key('unique_menus_count')
    end
  end
end
