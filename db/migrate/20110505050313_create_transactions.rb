class CreateTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.integer :tid
      t.string :name
      t.string :bank
      t.float :amount
      t.text :description
      t.datetime :trade_time

      t.references :user
      t.integer :sales_id

      t.timestamps
    end
  end

  def self.down
    drop_table :transactions
  end
end
