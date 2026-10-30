module TicketsHelper
  def ticket_status_options(ticket, user)
    case user&.role
    when "admin"
      ticket.status == "resolved" ? [["Closed", "closed"]] : []
    when "engineer"
      return [] unless ticket.assignee_id == user.id

      case ticket.status
      when "open"
        [["In Progress", "in_progress"]]
      when "in_progress"
        [["Resolved", "resolved"]]
      else
        []
      end
    when "requester"
      if ticket.requester_id == user.id && ticket.status == "resolved"
        [["Reopen", "open"], ["Closed", "closed"]]
      else
        []
      end
    else
      []
    end
  end
end
