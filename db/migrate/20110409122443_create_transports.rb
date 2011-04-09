class CreateTransports < ActiveRecord::Migration
  def self.up
    create_table :transports do |t|
      t.string :tran_type
      t.string :tran_id
      t.string :status
      t.string :from
      t.string :to
      t.boolean :real_tran, :default => false
      t.datetime :tran_time

      t.timestamps
    end
  end

  def self.down
    drop_table :transports
  end
end
