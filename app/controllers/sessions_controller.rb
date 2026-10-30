class SessionsController < ApplicationController
  before_action :login_user, only: [:destroy]

  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].to_s.strip.downcase)

    if user && user.authenticate(params[:session][:password])
      forwarding_url = session[:forwarding_url]

      reset_session
      log_in user

      redirect_to forwarding_url || root_path
    else
      flash.now[:danger] = "Invalid email/password combination"
      render :new
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to login_path
  end
end
