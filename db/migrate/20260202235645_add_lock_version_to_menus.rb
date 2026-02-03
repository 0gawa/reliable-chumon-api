class AddLockVersionToMenus < ActiveRecord::Migration[7.2]
  def change
    add_column :menus, :lock_version, :integer, default: 0, null: false
  end
end
