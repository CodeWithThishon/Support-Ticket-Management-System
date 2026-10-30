class PasswordResetsController < ApplicationController
  before_action :set_user, only: [:edit, :update]
  skip_before_action :login_user, only: [:new, :create, :edit, :update]

  def new
  end

  def create
    email = password_reset_params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    if user
      user.create_reset_digest
      PasswordResetMailer.reset_email(user).deliver_now
      Rails.logger.info("Development password reset URL: #{edit_password_reset_url(user, token: user.reset_token)}") if Rails.env.development?

      flash[:success] = "A password reset link has been sent."
      redirect_to login_path
    else
      flash[:danger] = "Invalid email address. Please enter a registered email."
      redirect_to new_password_reset_path
    end
  end

  def edit
    unless valid_reset_token?
      redirect_to new_password_reset_path,
                  alert: "This password reset link is invalid or has expired."
    end
  end

  def update
    unless valid_reset_token?
      redirect_to new_password_reset_path,
                  alert: "This password reset link is invalid or has expired."
      return
    end

    if @user.update(user_password_params)
      @user.clear_reset_digest
      reset_session
      flash[:success] = "Your password has been reset. Please log in."
      redirect_to login_path
    else
      render :edit
    end
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])

    unless @user
      redirect_to new_password_reset_path,
                  alert: "This password reset link is invalid or has expired."
    end
  end

  def valid_reset_token?
    @user &&
      @user.authenticated_reset_token?(params[:token]) &&
      !@user.password_reset_expired?
  end

  def password_reset_params
    params.require(:password_reset).permit(:email)
  end

  def user_password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
