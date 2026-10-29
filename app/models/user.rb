class User < ApplicationRecord
  before_validation :normalize_email

  has_many :requested_tickets, class_name: "Ticket", foreign_key: :requester_id, dependent: :restrict_with_error
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id, dependent: :nullify
  has_many :ticket_comments, dependent: :restrict_with_error
  has_many :ticket_activities, dependent: :restrict_with_error

  has_secure_password
  ROLES = %w[requester engineer admin].freeze

  validates :name, presence: true
  validates :email, presence: true,
            uniqueness: { case_sensitive: false }, format: {
      with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/,
      message: "must be a valid email address"
    }
  validates :role, inclusion: { in: ROLES }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
