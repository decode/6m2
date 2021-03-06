class CreateTasklogs < ActiveRecord::Migration
  def self.up
    create_table :tasklogs do |t|
      t.integer :task_id
      t.integer :user_id
      t.integer :worker_id

      t.string :user_name
      t.string :worker_name

      t.float :price
      t.float :point

      t.string :status
      t.string :description

      t.integer :worker_part_id #小号
      t.string :worker_part_name #小号名

      t.timestamps
    end
  end

  def self.down
    drop_table :tasklogs
  end
end
