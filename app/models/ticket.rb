class Ticket < ApplicationRecord
  before_validation :set_ticket, on: :create

  has_many :ticket_activities, dependent: :restrict_with_error
  has_many :ticket_comments, dependent: :destroy
  belongs_to :requester, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true

  PRIORITIES = %w[low medium high critical].freeze
  STATUSES = %w[open in_progress resolved closed].freeze
  STATUS_TRANSITIONS = {
    "open" => %w[in_progress].freeze,
    "in_progress" => %w[resolved].freeze,
    "resolved" => %w[open closed].freeze,
    "closed" => [].freeze
  }.freeze
  PRIORITY_ORDER = Arel.sql(
    "CASE priority " \
    "WHEN 'critical' THEN 1 " \
    "WHEN 'high' THEN 2 " \
    "WHEN 'medium' THEN 3 " \
    "WHEN 'low' THEN 4 END"
  )

  validates :ticket_number, presence: true, uniqueness: true
  validates :title, presence: true
  validates :description, presence: true
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }

  def self.visible_to(user)
    case user&.role
    when "admin"
      all
    when "engineer"
      where(assignee_id: user.id)
    when "requester"
      where(requester_id: user.id)
    else
      none
    end
  end

  def self.search(term)
    return all if term.blank?

    pattern = "%#{sanitize_sql_like(term.to_s.strip)}%"
    where("ticket_number ILIKE :pattern OR title ILIKE :pattern", pattern: pattern)
  end

  def self.filter_by(params, admin: false)
    relation = all
    status = params[:status].to_s
    priority = params[:priority].to_s

    relation = relation.where(status: status) if STATUSES.include?(status)
    relation = relation.where(priority: priority) if PRIORITIES.include?(priority)

    if admin
      assignee_id = params[:assignee_id].to_s
      requester_id = params[:requester_id].to_s
      relation = relation.where(assignee_id: assignee_id) if assignee_id.match?(/\A[1-9]\d*\z/)
      relation = relation.where(requester_id: requester_id) if requester_id.match?(/\A[1-9]\d*\z/)
      relation = relation.where(assignee_id: nil) if params[:unassigned] == "1"
    end

    relation
  end

  def self.ordered_by(sort)
    case sort.to_s
    when "oldest"
      order(created_at: :asc, id: :asc)
    when "priority"
      order(PRIORITY_ORDER, created_at: :desc, id: :desc)
    when "updated"
      order(updated_at: :desc, id: :desc)
    else
      order(created_at: :desc, id: :desc)
    end
  end

  def visible_to?(user)
    case user&.role
    when "admin"
      true
    when "engineer"
      assignee_id == user.id
    when "requester"
      requester_id == user.id
    else
      false
    end
  end

  alias commentable_by? visible_to?

  def change_status(new_status, user:, summary: nil)
    errors.clear

    unless STATUSES.include?(new_status)
      errors.add(:status, "is invalid")
      return false
    end

    unless STATUS_TRANSITIONS.fetch(status, []).include?(new_status)
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

    case new_status
    when "resolved"
      self.resolution_summary = summary
      self.resolved_at = Time.current
    when "open"
      self.resolved_at = nil
    when "closed"
      self.closed_at = Time.current
    end

    save
  end

  private

  def set_ticket
    self.ticket_number ||= "TKT-#{SecureRandom.hex(4).upcase}"
  end
end
