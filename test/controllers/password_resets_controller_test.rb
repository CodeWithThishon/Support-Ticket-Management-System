require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "shows the password reset request form" do
    get new_password_reset_path
    assert_response :success
  end

  test "sends a reset email for a registered email address" do
    user = users(:requester)

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post password_resets_path, params: {
        password_reset: { email: "  #{user.email.upcase}  " }
      }
    end

    assert_redirected_to login_path
    assert_equal "A password reset link has been sent.", flash[:success]
    assert user.reload.reset_digest.present?
  end

  test "shows an error and does not send email for an unknown address" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post password_resets_path, params: {
        password_reset: { email: "unknown@example.com" }
      }
    end

    assert_redirected_to new_password_reset_path
    assert_equal "Invalid email address. Please enter a registered email.", flash[:danger]
  end

  test "shows an error for a blank email address" do
    post password_resets_path, params: {
      password_reset: { email: " " }
    }

    assert_redirected_to new_password_reset_path
    assert_equal "Invalid email address. Please enter a registered email.", flash[:danger]
  end

  test "shows the password form for a valid reset token" do
    user = users(:requester)
    token = set_reset_token(user)

    get edit_password_reset_path(user, token: token)

    assert_response :success
  end

  test "rejects an invalid reset token" do
    user = users(:requester)
    set_reset_token(user)

    get edit_password_reset_path(user, token: "incorrect-token")

    assert_redirected_to new_password_reset_path
    assert_equal "This password reset link is invalid or has expired.", flash[:alert]
  end

  test "rejects an expired reset token" do
    user = users(:requester)
    token = set_reset_token(user, sent_at: 3.hours.ago)

    get edit_password_reset_path(user, token: token)

    assert_redirected_to new_password_reset_path
    assert_equal "This password reset link is invalid or has expired.", flash[:alert]
  end

  test "updates the password and clears reset credentials for a valid token" do
    user = users(:requester)
    token = set_reset_token(user)

    patch password_reset_path(user, token: token), params: {
      user: {
        password: "new-password-123",
        password_confirmation: "new-password-123"
      }
    }

    assert_redirected_to login_path
    assert_equal "Your password has been reset. Please log in.", flash[:success]
    assert user.reload.authenticate("new-password-123")
    assert_nil user.reset_digest
    assert_nil user.reset_sent_at
  end

  test "does not update the password when reset token is invalid" do
    user = users(:requester)
    set_reset_token(user)

    patch password_reset_path(user, token: "incorrect-token"), params: {
      user: {
        password: "new-password-123",
        password_confirmation: "new-password-123"
      }
    }

    assert_redirected_to new_password_reset_path
    assert user.reload.authenticate("password123")
  end

  test "does not update the password when confirmation does not match" do
    user = users(:requester)
    token = set_reset_token(user)

    patch password_reset_path(user, token: token), params: {
      user: {
        password: "new-password-123",
        password_confirmation: "different-password"
      }
    }

    assert_response :success
    assert user.reload.authenticate("password123")
    assert user.reload.reset_digest.present?
  end

  private

  def set_reset_token(user, token: "test-reset-token", sent_at: Time.current)
    user.update_columns(
      reset_digest: BCrypt::Password.create(token),
      reset_sent_at: sent_at
    )
    token
  end
end
