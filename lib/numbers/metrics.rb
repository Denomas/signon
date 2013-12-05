module Metrics
  def accounts_count
    [[:total, User.count]]
  end

  def accounts_count_by_state
    [[:active, User.active.count],
      [:suspended, User.suspended.count]]
  end

  def active_accounts_count_by_role
    User.active.count(group: :role)
  end

  def active_accounts_count_by_application
    User.active.joins(permissions: :application).where("permissions like '%signin%'").count(group: Doorkeeper::Application.arel_table['name'])
  end

  def active_accounts_count_by_organisation
    User.active.joins(:organisation).count(group: Organisation.arel_table['name']).to_a << ['None assigned', User.where(organisation_id: nil).count]
  end

  def active_admin_user_names
    ["admin", "superadmin"].collect do |role|
      [role, User.active.where(role: role).map {|u| "#{u.name} <#{u.email}>" }.sort.join(", ")]
    end
  end

  def accounts_count_by_days_since_last_sign_in
    [0...7, 7...15, 15...30, 30...45, 45...60, 60...90, 90...180, 180...10000000].inject([]) do |result, range|
      result << ["#{range.first} - #{range.last}", User.active.where(current_sign_in_at: range.last.days.ago...range.first.days.ago).count]
      result 
    end + [["never signed in", User.active.where(current_sign_in_at: nil).count]]
  end

  def accounts_count_how_often_user_has_signed_in
    [0, 1, 2...5, 5...10, 10...25, 25...50, 50...100, 100...200, 200...10000000].inject([]) do |result, range_or_value|
      if range_or_value.is_a?(Range)
        range = range_or_value
        result << ["#{range.first} - #{range.last}", User.active.where(sign_in_count: range.first...range.last).count]
      else
        result << ["#{range_or_value} time(s)", User.active.where(sign_in_count: range_or_value).count]
      end
      result 
    end
  end

  def active_accounts_count_by_email_domain
    User.active.count(group: "substring_index(email, '@', -1)")
  end

  def active_accounts_count_by_application_per_organisation
    Organisation.all.inject([]) do |result, org|
      User.active.joins(permissions: :application).where(organisation_id: org.id).where("permissions like '%signin%'").count(group: Doorkeeper::Application.arel_table['name']).to_a.map do |counts|
        result << [org.name, counts].flatten
      end
      result
    end
  end
end
