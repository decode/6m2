class Article < ActiveRecord::Base
  belongs_to :user

  validates_uniqueness_of :title, :content
  validates_presence_of :title, :content
end
