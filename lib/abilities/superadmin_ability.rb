class SuperadminAbility
  include CanCan::Ability

  def initialize(user)
    return unless user.role? :superadmin

    can [:read], Organisation
    can [:read, :create], BatchInvitation
    can [:read, :update], Doorkeeper::Application
    can [:read, :create, :update], SupportedPermission
    can [:read, :create, :update, :assign_role, :unlock, :invite!,
          :perform_admin_tasks, :suspend, :unsuspend, :resend_email_change, :cancel_email_change], User
  end
end
