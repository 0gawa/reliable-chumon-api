require 'swagger_helper'

RSpec.describe 'Admin Orders API', type: :request do
  path '/api/v1/admin/orders' do
    get 'List all orders' do
      tags 'Admin - Orders'
      produces 'application/json'
      description 'Returns all orders with optional filtering by table number and status'

      parameter name: :table_number, in: :query, type: :string, required: false,
                description: 'Filter by table number'
      parameter name: :status, in: :query, type: :string, required: false,
                description: 'Filter by order status',
                schema: { type: :string, enum: ['pending', 'confirmed', 'completed'] }

      response '200', 'orders found' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/Order' }

        let!(:orders) { create_list(:order, 3) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(3)
        end
      end

      response '200', 'filtered orders' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/Order' }

        let!(:order1) { create(:order, table_number: 'A-1', status: 'pending') }
        let!(:order2) { create(:order, table_number: 'A-2', status: 'completed') }
        let(:table_number) { 'A-1' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(1)
          expect(data.first['table_number']).to eq('A-1')
        end
      end
    end
  end

  path '/api/v1/admin/orders/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Order ID'

    get 'Retrieve a specific order' do
      tags 'Admin - Orders'
      produces 'application/json'

      response '200', 'order found' do
        schema '$ref' => '#/components/schemas/Order'

        let!(:order) { create(:order) }
        let(:id) { order.id }

        run_test!
      end

      response '404', 'order not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:id) { 99999 }

        run_test!
      end
    end
  end

  path '/api/v1/admin/orders/{id}/status' do
    parameter name: :id, in: :path, type: :integer, description: 'Order ID'

    patch 'Update order status' do
      tags 'Admin - Orders'
      consumes 'application/json'
      produces 'application/json'
      description 'Updates the status of an order (pending → confirmed → completed)'

      parameter name: :order, in: :body, schema: {
        type: :object,
        properties: {
          order: {
            type: :object,
            properties: {
              status: {
                type: :string,
                enum: ['pending', 'confirmed', 'completed'],
                example: 'confirmed'
              }
            },
            required: ['status']
          }
        }
      }

      response '200', 'status updated' do
        schema '$ref' => '#/components/schemas/Order'

        let!(:order_record) { create(:order, status: 'pending') }
        let(:id) { order_record.id }
        let(:order) { { order: { status: 'confirmed' } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('confirmed')
        end
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:order_record) { create(:order) }
        let(:id) { order_record.id }
        let(:order) { { order: { status: 'invalid_status' } } }

        run_test!
      end
    end
  end
end
