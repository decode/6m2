class CreateParticipants < ActiveRecord::Migration
  def self.up
    create_table :participants do |t|
      t.string :name
      t.string :part_id
      t.string :part_type
      t.string :role_type
      t.string :url
      t.string :status
      t.integer :score
      t.float :life
      t.boolean :active
      t.string :description

      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :participants
  end
end
