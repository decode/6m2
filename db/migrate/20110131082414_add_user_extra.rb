class AddUserExtra < ActiveRecord::Migration
  def self.up
    add_column :users, :im, :string
    add_column :users, :im_q, :string
    add_column :users, :bank_name, :string
    add_column :users, :bank_account, :integer
    add_column :users, :shop_taobao, :string
    add_column :users, :shop_taobao_url, :string
    add_column :users, :shop_paipai, :string
    add_column :users, :shop_paipai_url, :string
    add_column :users, :shop_youa, :string
    add_column :users, :shop_youa_url, :string
    add_column :users, :mobile, :string
    add_column :users, :person_id, :string
    add_column :users, :account_credit, :float, :default => 0
    add_column :users, :account_money, :float, :default => 0
    add_column :users, :payment_money, :float, :default => 0
    add_column :users, :score, :float, :default => 0
    add_column :users, :status, :string
  end

  def self.down
    remove_column :users, :im
    remove_column :users, :im_q
    remove_column :users, :bank_name
    remove_column :users, :bank_account
    remove_column :users, :shop_taobao
    remove_column :users, :shop_taobao_url
    remove_column :users, :shop_paipai
    remove_column :users, :shop_paipai_url
    remove_column :users, :shop_youa
    remove_column :users, :shop_youa_url
    remove_column :users, :mobile
    remove_column :users, :person_id
    remove_column :users, :account_credit #发布点
    remove_column :users, :account_money #发布点金额
    remove_column :users, :payment_money #货款
    remove_column :users, :score #积分
    remove_column :users, :status
  end
end
