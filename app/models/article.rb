class Article < ActiveRecord::Base
  belongs_to :user

  validates_uniqueness_of :title, :content
  validates_presence_of :title, :content

  # Add after upgrade to rails 3.1
  # 2012.5.14
  attr_accessible :title, :content, :article_type
end
