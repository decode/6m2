class CreateMessageBoxes < ActiveRecord::Migration
  def self.up
    create_table :message_boxes do |t|
      t.references :message
      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :message_boxes
  end
end
