class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      # 兑换比率
      t.float :point_ratio, :default => 1 # 1发布点价值1
      t.float :score_ratio, :default => 1

      t.float :init_required_point, :default => 0
      t.float :init_gift_point, :default => 2

      # 任务数级别
      t.integer :class1, :default => 100
      t.integer :class2, :default => 200
      t.integer :class3, :default => 500
      t.integer :class4, :default => 800
      t.integer :class5, :default => 1000

      t.float :task_punish, :default => 1
      t.float :charge_punish, :default => 1

      # 举报
      t.float:report_award, :default => 1
      t.float:report_punish, :default => 1

      # 自定义评价消耗点数
      t.float :custom_judge, :default => 0.2
      #t.float :extra_word, :default => 1

      # 真实交易号级别
      t.integer :real_level, :default => 5

      # 运单价格
      t.float :transport_price, :default => 0.2
      # 运单出售次数
      t.integer :times_limit, :default => 3

      t.integer :running_task, :default => 10
      t.integer :total_task, :default => 100
      t.integer :total_user, :default => 220

      t.timestamps
    end
  end

  def self.down
    drop_table :settings
  end
end
