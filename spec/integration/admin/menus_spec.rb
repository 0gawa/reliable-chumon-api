require 'swagger_helper'

RSpec.describe 'Admin Menus API', type: :request do
  path '/api/v1/admin/menus' do
    get 'List all menus' do
      tags 'Admin - Menus'
      produces 'application/json'
      description 'Returns all menus including unavailable ones'

      response '200', 'menus found' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/Menu' }

        let!(:menus) { create_list(:menu, 3) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(3)
        end
      end
    end

    post 'Create a menu' do
      tags 'Admin - Menus'
      consumes 'application/json'
      produces 'application/json'
      description 'Creates a new menu item'

      parameter name: :menu, in: :body, schema: {
        type: :object,
        properties: {
          menu: {
            type: :object,
            properties: {
              name: { type: :string, example: 'ハンバーグ' },
              price: { type: :integer, example: 1200 },
              category: { type: :string, example: 'メイン' },
              is_available: { type: :boolean, example: true },
              image_url: { type: :string, example: 'https://example.com/menu.jpg', nullable: true }
            },
            required: [ 'name', 'price', 'category' ]
          }
        }
      }

      response '201', 'menu created' do
        schema '$ref' => '#/components/schemas/Menu'

        let(:menu) do
          {
            menu: {
              name: 'ハンバーグ',
              price: 1200,
              category: 'メイン'
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq('ハンバーグ')
          expect(data['price']).to eq(1200)
        end
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/Error'

        let(:menu) do
          {
            menu: {
              name: '',
              price: -100
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']['code']).to eq('VALIDATION_ERROR')
        end
      end
    end
  end

  path '/api/v1/admin/menus/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Menu ID'

    get 'Retrieve a specific menu' do
      tags 'Admin - Menus'
      produces 'application/json'

      response '200', 'menu found' do
        schema '$ref' => '#/components/schemas/Menu'

        let!(:menu) { create(:menu) }
        let(:id) { menu.id }

        run_test!
      end

      response '404', 'menu not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:id) { 99999 }

        run_test!
      end
    end

    patch 'Update a menu' do
      tags 'Admin - Menus'
      consumes 'application/json'
      produces 'application/json'
      description 'Updates menu details. Supports optimistic locking with lock_version.'

      parameter name: :menu, in: :body, schema: {
        type: :object,
        properties: {
          menu: {
            type: :object,
            properties: {
              name: { type: :string },
              price: { type: :integer },
              is_available: { type: :boolean },
              category: { type: :string },
              lock_version: { type: :integer, description: 'For optimistic locking' }
            }
          }
        }
      }

      response '200', 'menu updated' do
        schema '$ref' => '#/components/schemas/Menu'

        let!(:menu_record) { create(:menu, name: 'Original Name') }
        let(:id) { menu_record.id }
        let(:menu) { { menu: { name: 'Updated Name', lock_version: menu_record.lock_version } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq('Updated Name')
        end
      end

      response '409', 'stale object error (optimistic locking)' do
        schema '$ref' => '#/components/schemas/Error'
        description 'Returned when lock_version is outdated'

        let!(:menu_record) { create(:menu) }
        let(:id) { menu_record.id }
        let(:menu) do
          menu_record.update!(name: 'Updated by another request')
          { menu: { name: 'My Update', lock_version: 0 } }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']['code']).to eq('STALE_OBJECT')
        end
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:menu_record) { create(:menu) }
        let(:id) { menu_record.id }
        let(:menu) { { menu: { price: -100 } } }

        run_test!
      end
    end

    delete 'Delete a menu' do
      tags 'Admin - Menus'
      produces 'application/json'

      response '204', 'menu deleted' do
        let!(:menu) { create(:menu) }
        let(:id) { menu.id }

        run_test!
      end
    end
  end
end
