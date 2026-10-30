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


  attr_accessor :reset_token

  def create_reset_digest
    self.reset_token = SecureRandom.urlsafe_base64
    update_columns(
      reset_digest: BCrypt::Password.create(reset_token),
      reset_sent_at: Time.current
    )
  end

  def authenticated_reset_token?(token)
    return false if reset_digest.nil? || token.blank?

    BCrypt::Password.new(reset_digest).is_password?(token)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def password_reset_expired?
    reset_sent_at.nil? || reset_sent_at < 2.hours.ago
  end

  def clear_reset_digest
    update_columns(reset_digest: nil, reset_sent_at: nil)
    self.reset_token = nil
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
