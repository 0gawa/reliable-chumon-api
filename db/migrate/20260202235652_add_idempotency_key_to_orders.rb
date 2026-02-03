class AddIdempotencyKeyToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :idempotency_key, :string, limit: 255
    add_index :orders, :idempotency_key, unique: true,
              where: "idempotency_key IS NOT NULL",
              name: 'index_orders_on_idempotency_key_not_null'
  end
end
