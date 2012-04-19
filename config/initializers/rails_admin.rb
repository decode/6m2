require "rails_admin/application_controller"

#RailsAdmin.config do |config|
  ##config.excluded_models << ClassName
  #config.model User do
    #list do
      #field :id
      #field :username
      #field :last_sign_in_at
      #field :last_sign_in_ip
      #field :sign_in_count
      #field :failed_attempts
      #field :account_credit
      #field :account_money
      #field :score
    #end
  #end
#end

module RailsAdmin
  class ApplicationController < ::ApplicationController
    access_control do
      allow :admin
    end
  end
end

