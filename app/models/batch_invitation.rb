class BatchInvitation < ActiveRecord::Base
  has_many :batch_invitation_users

  serialize :applications_and_permissions, Hash

  validates :outcome, inclusion: { :in => [nil, "success", "fail"] }

  def in_progress?
    outcome.nil?
  end

  class Job < Struct.new(:id)
    def perform(options = {})
    end
  end
end
