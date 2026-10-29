class ApplicationController < ActionController::Base
  include SessionsHelper

  before_action :login_user

  private

  def login_user
    unless logged_in?
      redirect_to login_path, alert: "Please log in first."
    end
  end
end
