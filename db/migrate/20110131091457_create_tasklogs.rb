class CreateTasklogs < ActiveRecord::Migration
  def self.up
    create_table :tasklogs do |t|
      t.integer :task_id
      t.integer :user_id
      t.integer :worker_id

      t.float :price
      t.float :point

      t.string :status
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :tasklogs
  end
end
