class UsersWithAccess
  attr_reader :scope, :application

  def initialize(scope, application)
    @scope = scope
    @application = application
  end

  def users
    scope
      .where(id: authorized_users_user_ids)
      .includes(:organisation)
  end

private
  def authorized_users_user_ids
     UserApplicationPermission.where(
      supported_permission: application.signin_permission,
      application: application
    ).select(:user_id)
  end
end
