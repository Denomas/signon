require 'test_helper'
require 'helpers/passphrase_support'

class EventLogTest < ActionDispatch::IntegrationTest
  include PassPhraseSupport

  setup do
    @admin = create(:admin_user)
    @user = create(:user)
  end

  test "record successful login" do
    visit root_path
    signin @user

    assert_equal EventLog::SUCCESSFUL_LOGIN, EventLog.for(@user).last.event
  end

  test "record unsuccessful login" do
    visit root_path
    signin(email: @user.email, password: :incorrect)

    assert_equal EventLog::UNSUCCESSFUL_LOGIN, EventLog.for(@user).last.event
  end

  test "record passphrase reset request" do
    visit root_path
    click_on "Forgot your passphrase?"
    fill_in "Email", with: @user.email
    click_on "Send me passphrase reset instructions"

    assert_equal EventLog::PASSPHRASE_RESET_REQUEST, EventLog.for(@user).first.event
  end

  test "record successful passphrase change" do
    new_password = "correct horse battery daffodil"
    visit root_path
    signin @user
    change_password(old: @user.password,
                    new: new_password,
                    new_confirmation: new_password)

    # multiple events are registered with the same time, order changes.
    assert_include EventLog.for(@user).map(&:event), EventLog::SUCCESSFUL_PASSPHRASE_CHANGE
  end

  test "record unsuccessful passphrase change" do
    visit root_path
    signin @user
    change_password(old: @user.password,
                    new: @user.password,
                    new_confirmation: @user.password)

    # multiple events are registered with the same time, order changes.
    assert_include EventLog.for(@user).map(&:event), EventLog::UNSUCCESSFUL_PASSPHRASE_CHANGE
  end

  test "record account locked if password entered too many times" do
    visit root_path
    7.times { signin(email: @user.email, password: :incorrect) }

    # multiple events are registered with the same time, order changes.
    assert_include EventLog.for(@user).map(&:event), EventLog::ACCOUNT_LOCKED
  end

  test "record account unlocked" do
    @user.lock_access!

    visit root_path
    signin @admin
    first_letter_of_name = @user.name[0]
    visit admin_users_path(letter: first_letter_of_name)
    click_on 'Unlock'

    # multiple events are registered with the same time, order changes.
    assert_include EventLog.for(@user).map(&:event), EventLog::MANUAL_ACCOUNT_UNLOCK
  end

  test "record user suspension" do
    visit root_path
    signin @admin
    first_letter_of_name = @user.name[0]
    visit admin_users_path(letter: first_letter_of_name)
    click_on "#{@user.name} <#{@user.email}>"
    click_on 'Suspend user'
    check 'Suspended?'
    fill_in 'Reason for suspension', with: 'Assaulting superior officer'
    click_on 'Save'

    assert_equal EventLog::ACCOUNT_SUSPENDED, EventLog.for(@user).last.event
  end

  test "record user unsuspension" do
    user = create(:user, suspended_at: 5.days.ago,
                         reason_for_suspension: 'Gross negligence')

    visit root_path
    signin @admin
    first_letter_of_name = user.name[0]
    visit admin_users_path(letter: first_letter_of_name)
    click_on "#{user.name} <#{user.email}>"
    click_on 'Unsuspend user'
    uncheck 'Suspended?'
    click_on 'Save'

    assert_equal EventLog::ACCOUNT_UNSUSPENDED, EventLog.for(user).last.event
  end

  test "record password expiration" do
    @user.password_changed_at = 100.days.ago; @user.save

    visit root_path
    signin @user

    assert_equal EventLog::PASSPHRASE_EXPIRED, EventLog.for(@user).first.event
  end

  test "users don't have permission to view account access log" do
    visit root_path
    signin @user

    visit admin_user_path(@user)
    click_on 'Account access log'

    assert page.has_content?("You do not have permission to perform this action")
  end

  test "admins have permission to view account access log" do
    @user.lock_access!
    visit root_path
    signin @admin
    visit admin_user_path(@user)
    click_on 'Account access log'

    assert_account_access_log_page_content(@user)
  end

  test "superadmins have permission to view account access log" do
    @user.lock_access!
    super_nintendo_chalmers = create(:superadmin_user)

    visit root_path
    signin super_nintendo_chalmers
    visit admin_user_path(@user)
    click_on 'Account access log'

    assert_account_access_log_page_content(@user)
  end

  test "organisation admins have permission to view their own users access log" do
    admin = create(:organisation_admin)
    user = create(:user_in_organisation, organisation: admin.organisation)
    user.lock_access!

    visit root_path
    signin admin
    visit admin_user_path(user)
    click_on 'Account access log'

    assert_account_access_log_page_content(user)
  end

  test "organisation admins don't have permission to view other users' access logs" do
    admin = create(:organisation_admin)

    visit root_path
    signin admin
    visit admin_user_path(@user)

    assert page.has_content?("You do not have permission to perform this action")
  end

  def assert_account_access_log_page_content(user)
    assert page.has_content?('Time')
    assert page.has_content?('Event')
    assert page.has_content?('Account locked')
    assert page.has_link?("#{user.name}")
  end
end
