class PagesController < ApplicationController
  skip_before_action :login_user, only: [:home]

  def home
    return unless logged_in?

    @tickets = Ticket.visible_to(current_user)

    @total_tickets = @tickets.count
    @open_tickets = @tickets.where(status: "open").count
    @in_progress_tickets = @tickets.where(status: "in_progress").count
    @resolved_tickets = @tickets.where(status: "resolved").count
    @closed_tickets = @tickets.where(status: "closed").count

    @recent_tickets = @tickets.order(created_at: :desc).limit(5)

    @unassigned_tickets = Ticket.where(assignee_id: nil).count if current_user.role == "admin"
  end
end
