class UserPolicy < BasePolicy

  def new?
    # invitations#new
    current_user.superadmin? || current_user.admin? || current_user.organisation_admin?
  end
  alias_method :index?, :new?

  def edit?
    case current_user.role
    when 'superadmin'
      true
    when 'admin'
      !record.superadmin?
    when 'organisation_admin'
      current_user.id == record.id ||
        (record.normal? && belong_to_same_organisation_subtree?(current_user, record))
    when 'normal'
      current_user.id == record.id
    end
  end
  alias_method :create?, :edit? # invitations#create
  alias_method :update?, :edit?
  alias_method :unlock?, :edit?
  alias_method :suspension?, :edit?
  alias_method :update_passphrase?, :edit?
  alias_method :cancel_email_change?, :edit?
  alias_method :resend_email_change?, :edit?
  alias_method :resend?, :edit?

  def event_logs?
    current_user.normal? ? false : edit?
  end

  def assign_role?
    current_user.superadmin?
  end

  def invite_in_batch?
    current_user.superadmin? || current_user.admin? ||
      (current_user.organisation_admin && belong_to_same_organisation_subtree?(current_user, record))
  end

  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.superadmin?
        scope.web_users
      elsif current_user.admin?
        scope.web_users.where(role: %w(admin organisation_admin normal))
      elsif current_user.organisation_admin?
        scope.web_users.where(role: %w(organisation_admin normal)).where(organisation_id: current_user.organisation_id)
      end
    end
  end

  private

  def belong_to_same_organisation_subtree?(current_user, record)
    current_user.organisation.subtree.pluck(:id).include?(record.organisation_id.to_i)
  end
end
