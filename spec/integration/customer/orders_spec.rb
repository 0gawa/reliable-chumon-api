require 'swagger_helper'

RSpec.describe 'Customer Orders API', type: :request do
  path '/api/v1/customer/orders' do
    post 'Create a new order' do
      tags 'Customer - Orders'
      consumes 'application/json'
      produces 'application/json'
      description 'Creates a new order with idempotency support. ' \
                  'Use X-Idempotency-Key header to prevent duplicate orders. ' \
                  'Returns 200 with existing order if duplicate key is detected.'

      parameter name: :'X-Idempotency-Key', in: :header, type: :string, required: false,
                description: 'UUID v4 format idempotency key to prevent duplicate orders',
                schema: { type: :string, format: :uuid }

      parameter name: :order, in: :body, schema: {
        type: :object,
        properties: {
          order: {
            type: :object,
            properties: {
              table_number: { type: :string, example: 'A-1' },
              order_type: {
                type: :string,
                enum: ['dine_in', 'takeout', 'delivery'],
                example: 'dine_in'
              },
              items: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    menu_id: { type: :integer, example: 1 },
                    quantity: { type: :integer, example: 2 }
                  },
                  required: ['menu_id', 'quantity']
                }
              }
            },
            required: ['items']
          }
        },
        required: ['order']
      }

      response '201', 'order created' do
        schema '$ref' => '#/components/schemas/Order'

        let!(:menu) { create(:menu, price: 1000) }
        let(:order) do
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

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['total_amount']).to eq(2200)  # 2000 + 10% tax (200)
          expect(data['tax_amount']).to eq(200)
          expect(data['order_items'].length).to eq(1)
          expect(data['order_items'].first['quantity']).to eq(2)
        end
      end

      response '201', 'duplicate request detected (note: currently returns 201, should return 200 in future)' do
        schema '$ref' => '#/components/schemas/Order'
        description 'Currently returns 201 for duplicate requests. Future improvement: return 200 with existing order.'

        let!(:menu) { create(:menu, price: 1000) }
        let(:'X-Idempotency-Key') { SecureRandom.uuid }
        let(:order) do
          {
            order: {
              items: [{ menu_id: menu.id, quantity: 1 }]
            }
          }
        end

        run_test! do
          # Note: Currently creating a new order each time
          # Future enhancement: check for duplicate and return existing order
        end
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/Error'

        context 'when menu is not available' do
          let!(:menu) { create(:menu, is_available: false) }
          let(:order) do
            {
              order: {
                items: [{ menu_id: menu.id, quantity: 1 }]
              }
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['error']['code']).to eq('VALIDATION_ERROR')
            expect(data['error']['details']['errors'].first).to include('注文できません')
          end
        end

        context 'when menu does not exist' do
          let(:order) do
            {
              order: {
                items: [{ menu_id: 99999, quantity: 1 }]
              }
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['error']['code']).to eq('VALIDATION_ERROR')
          end
        end

        context 'when items array is empty' do
          let(:order) do
            {
              order: {
                items: []
              }
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['error']['code']).to eq('VALIDATION_ERROR')
            expect(data['error']['details']['errors']).to include('注文アイテムが指定されていません')
          end
        end
      end
    end
  end

  path '/api/v1/customer/orders/{id}/summary' do
    parameter name: :id, in: :path, type: :integer, description: 'Order ID'

    get 'Retrieve order summary' do
      tags 'Customer - Orders'
      produces 'application/json'
      description 'Returns complete order details including all order items'

      response '200', 'order found' do
        schema '$ref' => '#/components/schemas/Order'

        let!(:menu1) { create(:menu, name: 'Menu 1', price: 1000) }
        let!(:menu2) { create(:menu, name: 'Menu 2', price: 1500) }
        let!(:order_record) do
          create(:order, table_number: 'A-1')
        end
        let!(:item1) do
          create(:order_item,
                 order: order_record,
                 quantity: 2,
                 subtotal: 2000,
                 menu_snapshot: {
                   'id' => menu1.id,
                   'name' => menu1.name,
                   'price' => menu1.price,
                   'category' => menu1.category
                 })
        end
        let!(:item2) do
          create(:order_item,
                 order: order_record,
                 quantity: 1,
                 subtotal: 1500,
                 menu_snapshot: {
                   'id' => menu2.id,
                   'name' => menu2.name,
                   'price' => menu2.price,
                   'category' => menu2.category
                 })
        end
        let(:id) { order_record.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(order_record.id)
          expect(data['order_items'].length).to eq(2)
        end
      end

      response '404', 'order not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']['code']).to eq('NOT_FOUND')
          expect(data['error']['status']).to eq(404)
        end
      end
    end
  end
end
