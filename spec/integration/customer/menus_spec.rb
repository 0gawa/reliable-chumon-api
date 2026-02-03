require 'swagger_helper'

RSpec.describe 'Customer Menus API', type: :request do
  path '/api/v1/customer/menus' do
    get 'List available menus for customers' do
      tags 'Customer - Menus'
      produces 'application/json'
      description 'Returns a list of available menus ordered by category and name. ' \
                  'Only shows menus where is_available is true.'

      response '200', 'menus found' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/Menu' }

        let!(:available_menus) { create_list(:menu, 3, is_available: true) }
        let!(:unavailable_menu) { create(:menu, is_available: false) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(3)
          expect(data.all? { |m| m['is_available'] }).to be true
        end
      end
    end
  end

  path '/api/v1/customer/menus/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Menu ID'

    get 'Retrieve a specific available menu' do
      tags 'Customer - Menus'
      produces 'application/json'
      description 'Returns details of a specific menu if it is available for ordering'

      response '200', 'menu found' do
        schema '$ref' => '#/components/schemas/Menu'

        let!(:menu) { create(:menu, name: 'Test Menu', is_available: true) }
        let(:id) { menu.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(menu.id)
          expect(data['name']).to eq('Test Menu')
          expect(data['is_available']).to be true
        end
      end

      response '404', 'menu not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']['code']).to eq('NOT_FOUND')
          expect(data['error']['status']).to eq(404)
        end
      end

      response '404', 'menu not available' do
        schema '$ref' => '#/components/schemas/Error'
        description 'Returns 404 if menu exists but is not available'

        let!(:menu) { create(:menu, is_available: false) }
        let(:id) { menu.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']['code']).to eq('NOT_FOUND')
        end
      end
    end
  end
end
