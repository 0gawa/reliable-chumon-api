class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.string :table_number, null: false
      t.integer :total_amount, null: false
      t.integer :tax_amount, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :ordered_at, null: false

      t.timestamps
    end

    add_index :orders, :table_number
    add_index :orders, :status
    add_index :orders, :ordered_at
  end
end
