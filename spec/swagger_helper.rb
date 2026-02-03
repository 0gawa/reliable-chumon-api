require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured, as per the Swagger instructions:
  # https://github.com/rswag/rswag#running-the-api-docs
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Restaurant Order Management API',
        version: 'v1',
        description: 'A production-ready REST API for managing restaurant orders with robust transaction integrity. ' \
                     'Provides reliable financial data for external payment systems. ' \
                     'Features include idempotent operations, optimistic/pessimistic locking, price snapshots, ' \
                     'daily aggregation, and comprehensive order lifecycle management.',
        contact: {
          name: 'API Support',
          url: 'https://github.com/0gawa/reliable-chumon-api'
        },
        license: {
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://{environment}.example.com',
          variables: {
            environment: {
              default: 'api',
              enum: ['api', 'staging']
            }
          },
          description: 'Production servers'
        }
      ],
      components: {
        schemas: {
          Menu: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: 'ハンバーグ' },
              price: { type: :integer, example: 1200 },
              category: { type: :string, example: 'メイン' },
              is_available: { type: :boolean, example: true },
              image_url: { type: :string, nullable: true, example: 'https://example.com/menu1.jpg' },
              lock_version: { type: :integer, example: 0 },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: ['id', 'name', 'price', 'category', 'is_available']
          },
          OrderItem: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              menu_id: { type: :integer, example: 1 },
              quantity: { type: :integer, example: 2 },
              unit_price: { type: :integer, example: 1200 },
              subtotal: { type: :integer, example: 2400 },
              menu_snapshot: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string },
                  price: { type: :integer },
                  category: { type: :string }
                }
              }
            },
            required: ['menu_id', 'quantity']
          },
          Order: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              table_number: { type: :string, example: 'A-1', nullable: true },
              order_type: {
                type: :string,
                enum: ['dine_in', 'takeout', 'delivery'],
                example: 'dine_in'
              },
              total_amount: { type: :integer, example: 2640 },
              tax_amount: { type: :integer, example: 240 },
              status: {
                type: :string,
                enum: ['pending', 'confirmed', 'completed'],
                example: 'pending'
              },
              ordered_at: { type: :string, format: 'date-time' },
              idempotency_key: { type: :string, format: 'uuid', nullable: true },
              order_items: {
                type: :array,
                items: { '$ref' => '#/components/schemas/OrderItem' }
              }
            },
            required: ['id', 'order_type', 'total_amount', 'tax_amount', 'status']
          },
          MenuDailyStat: {
            type: :object,
            properties: {
              id: { type: :integer },
              menu_id: { type: :integer },
              target_date: { type: :string, format: 'date' },
              total_quantity: { type: :integer, example: 15 },
              total_sales_amount: { type: :integer, example: 18000 },
              menu: { '$ref' => '#/components/schemas/Menu' }
            }
          },
          Error: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  status: { type: :integer, example: 404 },
                  code: { type: :string, example: 'NOT_FOUND' },
                  message: { type: :string, example: 'Resource not found' },
                  details: { type: :object },
                  timestamp: { type: :string, format: 'date-time' }
                },
                required: ['status', 'code', 'message', 'timestamp']
              }
            }
          }
        }
      },
      tags: [
        { name: 'Customer - Menus', description: 'Customer-facing menu operations' },
        { name: 'Customer - Orders', description: 'Customer-facing order operations' },
        { name: 'Admin - Menus', description: 'Admin menu management' },
        { name: 'Admin - Orders', description: 'Admin order management' },
        { name: 'Admin - Analytics', description: 'Sales analytics and reporting' }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
