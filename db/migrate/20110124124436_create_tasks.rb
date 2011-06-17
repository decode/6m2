class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string :title
      t.string :task_type
      t.string :description
      t.string :shop
      t.string :link
      t.float :price
      t.float :point
      t.string :status

      t.string :tran_type #物流公司
      t.string :tran_id #物流单号
      
      #时间标记 发布->接手->完成->确认
      t.datetime :published_time
      t.datetime :takeover_time
      t.datetime :pay_time
      t.datetime :transport_time
      t.datetime :finished_time
      t.datetime :confirmed_time

      #任务条件
      t.integer :worker_level, :default => 0
      t.integer :task_day, :default => 1 #1天内完成
      t.boolean :extra_word, :default => false #不填写评价
      t.integer :avoid_day, :default => 7 #7天內同一用户不能再拍
      #t.integer :task_level, :default => 0
      t.boolean :custom_judge, :default => false
      t.string :custom_judge_content
      t.integer :real_level, :default => 0 #实际接任务的帐户级别

      t.timestamps

      #用户关系
      t.references :user
      t.integer :worker_id
      t.integer :supervisor_id
      t.references :participant

      t.integer :worker_part_id #小号
      t.string :worker_part_name #小号名

      t.references :transport
    end
  end

  def self.down
    drop_table :tasks
  end
end
