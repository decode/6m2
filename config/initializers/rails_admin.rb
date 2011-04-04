require "rails_admin/application_controller"

RailsAdmin.config do |config|
  #config.excluded_models << ClassName
  #config.model User do
    #edit do
    #end
  #end
end

module RailsAdmin
  class ApplicationController < ::ApplicationController
    access_control do
      allow :admin
    end
  end
end

