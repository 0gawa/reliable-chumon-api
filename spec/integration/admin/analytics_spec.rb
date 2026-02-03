require 'swagger_helper'

RSpec.describe 'Admin Analytics API', type: :request do
  path '/api/v1/admin/analytics/daily' do
    get 'Get daily sales statistics' do
      tags 'Admin - Analytics'
      produces 'application/json'
      description 'Returns daily sales statistics with optional filtering by date range and menu'

      parameter name: :start_date, in: :query, type: :string, format: :date, required: false,
                description: 'Start date (defaults to 30 days ago)',
                example: '2026-01-01'
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false,
                description: 'End date (defaults to today)',
                example: '2026-01-31'
      parameter name: :menu_id, in: :query, type: :integer, required: false,
                description: 'Filter by specific menu ID'

      response '200', 'statistics found' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/MenuDailyStat' }

        let!(:menu) { create(:menu) }
        let!(:stat1) do
          create(:menu_daily_stat,
                 menu: menu,
                 target_date: Date.current,
                 total_quantity: 10,
                 total_sales_amount: 12000)
        end
        let!(:stat2) do
          create(:menu_daily_stat,
                 menu: menu,
                 target_date: Date.current - 1.day,
                 total_quantity: 8,
                 total_sales_amount: 9600)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to be >= 2
          expect(data.first).to have_key('menu')
        end
      end

      response '200', 'filtered statistics' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/MenuDailyStat' }

        let!(:menu) { create(:menu) }
        let!(:stat) do
          create(:menu_daily_stat,
                 menu: menu,
                 target_date: '2026-01-15')
        end
        let(:start_date) { '2026-01-01' }
        let(:end_date) { '2026-01-31' }
        let(:menu_id) { menu.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.all? { |s| s['menu_id'] == menu.id }).to be true
        end
      end
    end
  end

  path '/api/v1/admin/analytics/summary' do
    get 'Get sales summary' do
      tags 'Admin - Analytics'
      produces 'application/json'
      description 'Returns aggregated sales summary for a date range'

      parameter name: :start_date, in: :query, type: :string, format: :date, required: false,
                description: 'Start date (defaults to 30 days ago)'
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false,
                description: 'End date (defaults to today)'

      response '200', 'summary retrieved' do
        schema type: :object,
               properties: {
                 start_date: { type: :string, format: :date },
                 end_date: { type: :string, format: :date },
                 total_sales_amount: { type: :integer, example: 50000 },
                 total_quantity: { type: :integer, example: 42 },
                 unique_menus_count: { type: :integer, example: 5 }
               },
               required: ['start_date', 'end_date', 'total_sales_amount', 'total_quantity', 'unique_menus_count']

        let!(:menu1) { create(:menu) }
        let!(:menu2) { create(:menu) }
        let!(:stat1) do
          create(:menu_daily_stat,
                 menu: menu1,
                 target_date: Date.current,
                 total_quantity: 15,
                 total_sales_amount: 18000)
        end
        let!(:stat2) do
          create(:menu_daily_stat,
                 menu: menu2,
                 target_date: Date.current,
                 total_quantity: 10,
                 total_sales_amount: 12000)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('total_sales_amount')
          expect(data).to have_key('total_quantity')
          expect(data).to have_key('unique_menus_count')
          expect(data['total_sales_amount']).to be >= 30000
          expect(data['total_quantity']).to be >= 25
        end
      end
    end
  end
end
