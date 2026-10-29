class PagesController < ApplicationController
  def home
    @total_tickets = Ticket.count
    @open_tickets = Ticket.where(status: "open").count
    @in_progress_tickets = Ticket.where(status: "in_progress").count
    @resolved_tickets = Ticket.where(status: "resolved").count
    @closed_tickets = Ticket.where(status: "closed").count
    @unassigned_tickets = Ticket.where(assignee_id: nil).count
 @engineer_ticket_counts = User.where(role: "engineer")
                              .left_joins(:assigned_tickets)
                              .group("users.id", "users.name")
                              .count("tickets.id")
  end
end
