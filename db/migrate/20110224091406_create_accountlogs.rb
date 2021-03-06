class CreateAccountlogs < ActiveRecord::Migration
  def self.up
    create_table :accountlogs do |t|
      t.integer :user_id
      t.integer :operator_id
      t.string :user_name
      t.string :operator_name

      t.integer :trade_id
      t.string :description
      t.float :amount
      t.string :log_type

      t.timestamps
    end
  end

  def self.down
    drop_table :accountlogs
  end
end
