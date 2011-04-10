class UserTransport < ActiveRecord::Base
  belongs_to :user
  belongs_to :transport
end
