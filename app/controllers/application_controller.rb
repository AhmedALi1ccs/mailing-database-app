# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  config.require_master_key = true
end