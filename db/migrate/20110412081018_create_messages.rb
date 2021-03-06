class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.string :title
      t.string :content
      t.string :msg_type
      t.integer :priority
      t.string :status

      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
