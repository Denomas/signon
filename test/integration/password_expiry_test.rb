require 'test_helper'
require 'helpers/password_support'

class PasswordExpiryTest < ActionDispatch::IntegrationTest
  include PasswordSupport

  PROMPT_TO_CHANGE_PASSWORD = "Your password has expired. Please choose a new password".freeze

  context "logging in with a brand new user" do
    setup do
      @user = create(:user)
    end

    should "not ask the user to change their password" do
      visit new_user_session_path

      signin_with(@user)
      refute_response_contains(PROMPT_TO_CHANGE_PASSWORD)
    end
  end

  context "logging in with a user with an expired password" do
    setup do
      @user = create(:user, password_changed_at: 91.days.ago)
      @new_password = "some 3v3n more s3cure password"
    end

    should "force the user to change their password" do
      visit new_user_session_path

      signin_with(@user)
      assert_response_contains(PROMPT_TO_CHANGE_PASSWORD)

      reset_expired_password(@user.password, @new_password, @new_password)
      assert_response_contains("Your new password is saved")

      assert_equal root_url, current_url
    end

    should "remember where the user was trying to get to before the password reset" do
      visit "/users/#{@user.id}/edit_email_or_password?arbitrary=1"

      signin_with(@user)
      reset_expired_password(@user.password, @new_password, @new_password)

      assert_current_url "/users/#{@user.id}/edit_email_or_password?arbitrary=1"
    end

    should "continue prompting for a new password if an incorrect password was provided" do
      visit new_user_session_path
      signin_with(@user)

      reset_expired_password("nonsense", @new_password, @new_password)

      visit new_user_session_path
      assert_response_contains(PROMPT_TO_CHANGE_PASSWORD)
    end

    should "continue prompting for a new password if the password was not confirmed" do
      visit new_user_session_path
      signin_with(@user)

      reset_expired_password(@user.password, @new_password, "rubbish")

      visit new_user_session_path
      assert_response_contains(PROMPT_TO_CHANGE_PASSWORD)
    end

    should "continue prompting for a new password if the user navigates away from the password reset page" do
      visit new_user_session_path
      signin_with(@user)

      visit new_user_session_path
      assert_response_contains(PROMPT_TO_CHANGE_PASSWORD)
    end
  end
end