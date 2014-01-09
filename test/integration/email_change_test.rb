require 'test_helper'
require 'helpers/user_account_operations'
 
class EmailChangeTest < ActionDispatch::IntegrationTest
  include UserAccountOperations

  context "by an admin" do
    setup do
      @admin = create(:user, role: "admin")
    end

    context "for an active user" do
      should "trigger a confirmation email to the user" do
        user = create(:user)

        visit new_user_session_path
        signin(@admin)
        admin_changes_email_address(user: user, new_email: "new@email.com")

        assert_equal "new@email.com", last_email.to[0]
        assert_equal 'Confirm your email change', last_email.subject

        user.reload
        confirm_email_change(confirmation_token: user.confirmation_token,
                             password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z")
        assert_response_contains("Your account was successfully confirmed. You are now signed in.")
      end
    end

    context "for a user who hasn't accepted their invite yet" do
      should "resend a confirmation email" do
        user = User.invite!(name: "Jim", email: "jim@web.com")

        visit new_user_session_path
        signin(@admin)
        admin_changes_email_address(user: user, new_email: "new@email.com")

        assert_equal "new@email.com", last_email.to[0]
        assert_equal 'Please confirm your account', last_email.subject

        user.reload
        accept_invitation(invitation_token: user.invitation_token,
                          password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z")
        assert_response_contains("Your passphrase was set successfully. You are now signed in.")
      end
    end
  end
end
