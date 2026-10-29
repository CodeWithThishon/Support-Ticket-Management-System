class Ticket < ApplicationRecord
  before_validation :set_ticket, on: :create

  has_many :ticket_activities,dependent: :restrict_with_error
  has_many :ticket_comments, dependent: :destroy
  belongs_to :requester, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true

  PRIORITIES = %w[low medium high critical].freeze
  STATUSES = %w[open in_progress resolved closed].freeze

  validates :ticket_number, presence: true, uniqueness: true
  validates :title, presence: true
  validates :description, presence: true
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }



  def change_status(new_status, user:, summary: nil)
    errors.clear

    allowed_transitions = {
      "open" => ["in_progress"],
      "in_progress" => ["resolved"],
      "resolved" => ["open", "closed"],
      "closed" => []
    }

    unless self.class::STATUSES.include?(new_status)
      errors.add(:status, "is invalid")
      return false
    end

    unless allowed_transitions.fetch(status, []).include?(new_status)
      errors.add(:status, "transition is not allowed")
      return false
    end

    case new_status
    when "in_progress"
      unless user.role == "engineer" &&
             assignee_id == user.id
        errors.add(:status, "can only be updated by the assigned engineer")
        return false
      end

      if assignee.nil?
        errors.add(:assignee, "must be assigned before work starts")
        return false
      end

    when "resolved"
      unless user.role == "engineer" &&
             assignee_id == user.id
        errors.add(:status, "can only be updated by the assigned engineer")
        return false
      end

      if summary.blank?
        errors.add(:resolution_summary, "is required")
        return false
      end

    when "open"
      unless user.role == "requester" &&
             requester_id == user.id
        errors.add(:status, "can only be reopened by the requester")
        return false
      end

    when "closed"
      unless user.role == "admin" ||
             (user.role == "requester" &&
               requester_id == user.id)
        errors.add(:status, "can only be closed by the admin or requester")
        return false
      end
    end

    self.status = new_status

    if new_status == "resolved"
      self.resolution_summary = summary
      self.resolved_at = Time.current
    elsif new_status == "open"
      self.resolved_at = nil
    elsif new_status == "closed"
      self.closed_at = Time.current
    end

    save
  end


  private
  def set_ticket
    self.ticket_number ||= "TKT-#{SecureRandom.hex(4).upcase}"
  end
end
