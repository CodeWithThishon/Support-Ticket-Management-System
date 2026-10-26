class User < ApplicationRecord
  before_validation :normalize_email
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
