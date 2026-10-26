class Ticket < ApplicationRecord
  belongs_to :requester
  belongs_to :assignee
end
