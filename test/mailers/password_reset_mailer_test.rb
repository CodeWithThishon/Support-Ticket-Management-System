require 'test_helper'

class PasswordResetMailerTest < ActionMailer::TestCase
  test "reset_email" do
    user = users(:requester)
    user.reset_token = "test-reset-token"

    mail = PasswordResetMailer.reset_email(user)

    assert_equal "Reset your password", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["noreply@example.com"], mail.from
    assert_match user.name, mail.body.encoded
  end

end
