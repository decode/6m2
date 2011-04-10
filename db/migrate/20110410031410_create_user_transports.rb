class CreateUserTransports < ActiveRecord::Migration
  def self.up
    create_table :user_transports do |t|
      t.references :user
      t.references :transport

      t.timestamps
    end
  end

  def self.down
    drop_table :user_transports
  end
end
