class CreateMenuDailyStats < ActiveRecord::Migration[7.2]
  def change
    create_table :menu_daily_stats do |t|
      t.references :menu, null: false, foreign_key: true
      t.date :aggregation_date, null: false
      t.integer :total_quantity, default: 0, null: false
      t.integer :total_sales_amount, default: 0, null: false

      t.timestamps
    end

    add_index :menu_daily_stats, [ :menu_id, :aggregation_date ], unique: true
    add_index :menu_daily_stats, :aggregation_date
  end
end
