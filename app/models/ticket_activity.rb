class TicketActivity < ApplicationRecord
  belongs_to :ticket
  belongs_to :user

  validates :action, presence: true
end
