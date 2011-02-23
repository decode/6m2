class InitSetting < ActiveRecord::Migration
  def self.up
    Setting.create!
  end

  def self.down
    Setting.first.destroy
  end
end
