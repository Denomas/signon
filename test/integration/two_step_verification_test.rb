#encoding: utf-8
require 'test_helper'
require 'helpers/passphrase_support'

class TwoStepVerificationTest < ActionDispatch::IntegrationTest
  context "setting a 2SV code" do
    setup do
      @new_secret = ROTP::Base32.random_base32
      @original_secret = ROTP::Base32.random_base32
      ROTP::Base32.stubs(random_base32: @new_secret)
    end

    context "with an existing 2SV setup" do
      setup do
        @user = create(:user, email: "jane.user@example.com", otp_secret_key: @original_secret)
        visit new_user_session_path
        signin_with_2sv(@user)
        visit two_step_verification_path
      end

      should "show the TOTP secret and a warning" do
        assert_response_contains "Enter the code manually: #{@new_secret}"
        assert_response_contains "Setting up a new phone will replace your existing one. You will only be able to sign in with your new phone."
      end

      should "reject an invalid code, reuse the secret and log the rejection" do
        fill_in "code", with: "abcdef"
        click_button "submit_code"

        assert_response_contains "Sorry that code didn’t work. Please try again."
        assert_response_contains "Enter the code manually: #{@new_secret}"
        assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_CHANGE_FAILED, uid: @user.uid).count
      end

      should "accept a valid code, persist the secret and log the event" do
        enter_2sv_code(@new_secret)

        assert_response_contains "2-step verification phone changed successfully"
        assert_equal @new_secret, @user.reload.otp_secret_key
        assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_CHANGED, uid: @user.uid).count
      end

      should "require the code again on next login" do
        enter_2sv_code(@new_secret)

        within("main") do
          click_link "Sign out"
        end

        signin_with_2sv(@user)
      end
    end

    context "for a user without an existing 2SV setup" do
      setup do
        @user = create(:admin_user, email: "jane.user@example.com")
        visit users_path
        signin(@user)
        visit two_step_verification_path
      end

      should "show the TOTP secret" do
        assert_response_contains "Enter the code manually: #{@new_secret}"
      end

      should "reject an invalid code, reuse the secret and log the rejection" do
        fill_in "code", with: "abcdef"
        click_button "submit_code"

        assert_response_contains "Sorry that code didn’t work. Please try again."
        assert_response_contains "Enter the code manually: #{@new_secret}"
        assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_ENABLE_FAILED, uid: @user.uid).count
      end

      should "accept a valid code, persist the secret and log the event" do
        enter_2sv_code(@new_secret)

        assert_response_contains "2-step verification set up"
        assert_equal @new_secret, @user.reload.otp_secret_key
        assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_ENABLED, uid: @user.uid).count
      end
    end
  end
end
