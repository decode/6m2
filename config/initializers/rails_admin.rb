require "rails_admin/application_controller"

RailsAdmin.config do |config|
  #config.excluded_models << ClassName
  config.model User do
    edit do
      field :username
      field :email
      field :password
      field :password_confirmation
      field :created_at
      field :updated_at
      field :account_credit
      field :account_money
      field :payment_money
      field :status
      field :score
      field :role_objects
      field :sign_in_count
      field :current_sign_in_at
      field :current_sign_in_ip
      field :locked_at
    end
  end
end

module RailsAdmin
  class ApplicationController < ::ApplicationController
    access_control do
      allow :admin
    end
  end
end

