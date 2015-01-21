module UsersHelper
  def organisation_options(form_builder)
    accessible_organisations = policy_scope(Organisation)
    options_from_collection_for_select(accessible_organisations, :id,
      :name_with_abbreviation, selected: form_builder.object.organisation_id)
  end

  def organisation_select_options
    { include_blank: is_org_admin? ? false : 'None' }
  end

  def user_email_tokens(user = current_user)
    [ user.email ] + DeviseZxcvbn::EmailTokeniser.split(user.email)
  end

  def minimum_password_length
    User.password_length.min
  end

  def edit_user_path_by_user_type(user)
    user.api_user? ? edit_api_user_path(user) : edit_user_path(user)
  end

  def is_org_admin?
    current_user.role == 'organisation_admin'
  end

  def sync_needed?(permissions)
    permissions.map(&:updated_at).max > permissions.map(&:last_synced_at).max
  end
end
