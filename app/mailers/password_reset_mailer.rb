class PasswordResetMailer < ApplicationMailer
  def reset_email(user)
    @user = user
    @token = user.reset_token

    mail(
      to: @user.email,
      subject: "Reset your password"
    )
  end
end
