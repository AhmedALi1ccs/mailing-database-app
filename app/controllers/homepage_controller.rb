class HomepageController < ApplicationController
  def index
    render json: { message: "Welcome to the Mailing Database API", status: "online" }
  end
end
