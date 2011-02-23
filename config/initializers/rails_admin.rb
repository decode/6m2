require "rails_admin/application_controller"

RailsAdmin.config do |config|
  #config.excluded_models << ClassName
end

module RailsAdmin
  class ApplicationController < ::ApplicationController
    access_control do
      allow :admin
    end
  end
end

