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

      t.integer :workder_part_id #小号
      t.string :worker_part_name #小号名

      #时间标记 发布->接手->完成->确认
      t.datetime :published_time
      t.datetime :takeover_time
      t.datetime :pay_time
      t.datetime :transport_time
      t.datetime :finished_time
      t.datetime :confirmed_time

      t.timestamps
    end
  end

  def self.down
    drop_table :tasklogs
  end
end
