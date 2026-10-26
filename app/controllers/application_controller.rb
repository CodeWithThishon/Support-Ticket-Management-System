class ApplicationController < ActionController::Base
  include SessionsHelper

  before_action :require_login

  private

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please log in first."
    end
  end
end
