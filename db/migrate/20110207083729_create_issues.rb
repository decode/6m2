class CreateIssues < ActiveRecord::Migration
  def self.up
    create_table :issues do |t|
      t.string :title
      t.string :content
      t.string :description
      t.string :memo
      t.string :status
      t.string :itype
      t.integer :target_id

      t.timestamps

      t.references :user
      t.integer :dealer_id
    end
  end

  def self.down
    drop_table :issues
  end
end
