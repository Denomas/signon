require 'test_helper'

class ::Doorkeeper::ApplicationTest < ActiveSupport::TestCase

  context "supported_permission_strings" do

    should "return a list of string permissions, merging in the defaults" do
      user = FactoryGirl.create(:user)
      app = FactoryGirl.create(:application)
      FactoryGirl.create(:supported_permission, name: "write", application: app)
      assert_equal ["signin", "write"], app.supported_permission_strings(user)
    end

    should "only show permissions that organisation admins themselves have" do
      user = FactoryGirl.create(:user_in_organisation, role: 'organisation_admin')
      app = FactoryGirl.create(:application)
      FactoryGirl.create(:supported_permission, name: "write", application: app, delegatable: true)
      FactoryGirl.create(:supported_permission, name: "approve", application: app, delegatable: true)
      FactoryGirl.create(:permission, user: user, application: app, permissions: ['write'])

      assert_equal ["write"], app.supported_permission_strings(user)
    end

    should "only show delegatable permissions to organisation admins" do
      user = FactoryGirl.create(:user_in_organisation, role: 'organisation_admin')
      app = FactoryGirl.create(:application)
      FactoryGirl.create(:supported_permission, name: "write", application: app, delegatable: true)
      FactoryGirl.create(:supported_permission, name: "approve", application: app, delegatable: false)
      FactoryGirl.create(:permission, user: user, application: app, permissions: ['write', 'approve'])

      assert_equal ["write"], app.supported_permission_strings(user)
    end

  end

  context "scopes" do
    should "return applications that the user can signin into" do
      user = FactoryGirl.create(:user)
      application = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:permission, permissions: ['signin'], user: user, application: application)

      assert_include Doorkeeper::Application.can_signin(user), application
    end

    should "not return applications that the user can't signin into" do
      user = FactoryGirl.create(:user)
      application = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:permission, permissions: ['signin'],
                    user: FactoryGirl.create(:user), application: application)

      assert_empty Doorkeeper::Application.can_signin(user)
    end

    should "return applications that support delegation of signin permission" do
      application = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:supported_permission, name: 'signin',
                    delegatable: true, application: application)

      assert_include Doorkeeper::Application.with_signin_delegatable, application
    end

    should "not return applications that don't support delegation of signin permission" do
      application = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:supported_permission, name: 'signin',
                    delegatable: false, application: application)

      assert_empty Doorkeeper::Application.with_signin_delegatable
    end
  end
end
