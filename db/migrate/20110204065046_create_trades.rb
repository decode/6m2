class CreateTrades < ActiveRecord::Migration
  def self.up
    create_table :trades do |t|
      t.string :price
      t.string :status
      t.string :description
      t.string :trade_type

      t.references :user
      t.integer :to_id

      t.timestamps
    end
  end

  def self.down
    drop_table :trades
  end
end
