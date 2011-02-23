class CreatePenalties < ActiveRecord::Migration
  def self.up
    create_table :penalties do |t|
      t.float :point
      t.float :money
      t.string :reason

      t.timestamps

      t.references :issue
      t.references :user
    end
  end

  def self.down
    drop_table :penalties
  end
end
