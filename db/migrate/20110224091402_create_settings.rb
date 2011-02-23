class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      # 兑换比率
      t.float :point_ratio, :default => 1 # 1发布点价值1
      t.integer :score_ratio, :default => 1

      t.float :init_required_point, :default => 10

      # 任务数级别
      t.integer :class1, :default => 100
      t.integer :class2, :default => 200
      t.integer :class3, :default => 500
      t.integer :class4, :default => 800
      t.integer :class5, :default => 1000

      t.integer :task_punish, :default => 1
      t.integer :charge_punish, :default => 1

      # 举报
      t.integer :report_award, :default => 1
      t.integer :report_punish, :default => 1

      # 自定义评价消耗点数
      t.float :custom_judge, :default => 1
      
      t.integer :real_level, :default => 10

      t.timestamps
    end
  end

  def self.down
    drop_table :settings
  end
end
