require 'password_migration'

class User < ActiveRecord::Base
  self.include_root_in_json = true

  devise :database_authenticatable, :recoverable, :trackable,
         :validatable, :timeoutable, :lockable,                # devise core model extensions
         :invitable,    # in devise_invitable gem
         :suspendable,  # in signonotron2/lib/devise/models/suspendable.rb
         :strengthened, # in signonotron2/lib/devise/models/strengthened.rb
         :encryptable,
         :confirmable,
         :password_expirable

  ROLES = %w[normal organisation_admin admin superadmin]
  NORMAL_ATTRIBUTES = [:uid, :name, :email, :password, :password_confirmation]
  attr_accessible *NORMAL_ATTRIBUTES

  ADMIN_ATTRIBUTES = [:permissions_attributes, :organisation_id, :unconfirmed_email, :confirmation_token]
  attr_accessible *(NORMAL_ATTRIBUTES + ADMIN_ATTRIBUTES), as: [:admin, :organisation_admin]

  SUPERADMIN_ATTRIBUTES = [:role]
  attr_accessible *(NORMAL_ATTRIBUTES + ADMIN_ATTRIBUTES + SUPERADMIN_ATTRIBUTES), as: :superadmin
  attr_readonly :uid

  validates :name, presence: true
  validates :reason_for_suspension, presence: true, if: proc { |u| u.suspended? }
  validates :role, inclusion: { in: ROLES }

  has_many :authorisations, :class_name => 'Doorkeeper::AccessToken', :foreign_key => :resource_owner_id
  has_many :permissions, inverse_of: :user
  has_many :batch_invitations
  belongs_to :organisation

  before_create :generate_uid
  after_create :update_stats

  accepts_nested_attributes_for :permissions, :allow_destroy => true

  def role?(base_role)
    # each role can do everything that the previous role can do
    ROLES.index(base_role.to_s) <= ROLES.index(role)
  end

  def generate_uid
    self.uid = UUID.generate
  end

  def invited_but_not_accepted
    !invitation_sent_at.nil? && invitation_accepted_at.nil?
  end

  def authorised_applications
    authorisations.group_by(&:application).map(&:first)
  end
  alias_method :applications_used, :authorised_applications

  def grant_permission(application, permission)
    grant_permissions(application, [permission])
  end

  def grant_permissions(application, permissions)
    permission_record = self.permissions.find_by_application_id(application.id) || self.permissions.build(application_id: application.id)
    new_permissions = Set.new(permission_record.permissions || [])
    new_permissions += permissions

    permission_record.permissions = new_permissions.to_a
    permission_record.save!
  end

  # Required for devise_invitable to set role and permissions
  def self.inviter_role(inviter)
    inviter.nil? ? :default : inviter.role.to_sym
  end

  def invite!
    # For us, a user is "confirmed" when they're created, even though this is
    # conceptually confusing.
    # It means that the password reset flow works when you've been invited but
    # not yet accepted.
    # Devise Invitable used to behave this way and then changed in v1.1.1
    self.confirmed_at = Time.zone.now
    super
  end

  # Override Devise so that, when a user has been invited with one address
  # and then it is changed, we can send a new invitation email, rather than
  # a confirmation email (and hence they'll be in the correct flow re setting
  # their first password)
  def postpone_email_change?
    if invited_but_not_yet_accepted?
      false
    else
      super
    end
  end

  def invited_but_not_yet_accepted?
    invitation_sent_at.present? && invitation_accepted_at.nil?
  end

  def update_stats
    Statsd.new(::STATSD_HOST).increment("#{::STATSD_PREFIX}.users.created")
  end

  include PasswordMigration
end
