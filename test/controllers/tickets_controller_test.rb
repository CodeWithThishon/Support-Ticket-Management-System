require 'test_helper'

class TicketsControllerTest < ActionDispatch::IntegrationTest

  test "engineer cannot assign a ticket" do
    engineer = users(:engineer)
    ticket = tickets(:open_ticket)
    post login_path, params: {
      session: {
        email: engineer.email,
        password: "password123"
      }
    }
    patch assign_ticket_path(ticket), params: {
      assignee_id: users(:admin).id
    }
    assert_redirected_to ticket_path(ticket)
    assert_not_equal users(:admin).id, ticket.reload.assignee_id
  end

  test "engineer cannot change ticket priority" do
    engineer = users(:engineer)
    ticket = tickets(:open_ticket)
    original_priority = ticket.priority
    post login_path, params: {
      session: {
        email: engineer.email,
        password: "password123"
      }
    }
    patch update_priority_ticket_path(ticket), params: {
      priority: "critical"
    }
    assert_redirected_to ticket_path(ticket)
    assert_equal original_priority, ticket.reload.priority
  end


  test "admin can assign a ticket to an engineer" do
    admin = users(:admin)
    ticket = tickets(:open_ticket)
    engineer = users(:engineer)

    post login_path, params: {
      session: {
        email: admin.email,
        password: "password123"
      }
    }

    patch assign_ticket_path(ticket), params: {
      assignee_id: engineer.id
    }

    assert_redirected_to ticket_path(ticket)
    assert_equal engineer.id, ticket.reload.assignee_id
  end

  test "admin can change ticket priority" do
    admin = users(:admin)
    ticket = tickets(:open_ticket)

    post login_path, params: {
      session: {
        email: admin.email,
        password: "password123"
      }
    }

    patch update_priority_ticket_path(ticket), params: {
      priority: "critical"
    }

    assert_redirected_to ticket_path(ticket)
    assert_equal "critical", ticket.reload.priority
  end



  test "admin assigning the same engineer keeps the assignment unchanged" do
    admin = users(:admin)
    ticket = tickets(:open_ticket)
    engineer = users(:engineer)

    ticket.update!(assignee: engineer)

    post login_path, params: {
      session: {
        email: admin.email,
        password: "password123"
      }
    }

    patch assign_ticket_path(ticket), params: {
      assignee_id: engineer.id
    }

    assert_redirected_to ticket_path(ticket)
    assert_equal engineer.id, ticket.reload.assignee_id
  end


  test "admin priority change creates an activity record" do
    admin = users(:admin)
    ticket = tickets(:open_ticket)
    old_count = ticket.ticket_activities.count

    post login_path, params: {
      session: {
        email: admin.email,
        password: "password123"
      }
    }

    patch update_priority_ticket_path(ticket), params: {
      priority: "critical"
    }

    assert_equal old_count + 1, ticket.ticket_activities.reload.count
    assert_equal "priority_changed", ticket.ticket_activities.last.action
  end


  test "admin assigning the same engineer does not create duplicate activity" do
    admin = users(:admin)
    ticket = tickets(:open_ticket)
    engineer = users(:engineer)

    ticket.update!(assignee: engineer)
    old_count = ticket.ticket_activities.count

    post login_path, params: {
      session: {
        email: admin.email,
        password: "password123"
      }
    }

    patch assign_ticket_path(ticket), params: {
      assignee_id: engineer.id
    }

    assert_equal old_count, ticket.ticket_activities.reload.count
  end

  test "admin selecting the same priority does not create duplicate activity" do
    admin = users(:admin)
    ticket = tickets(:open_ticket)
    old_priority = ticket.priority
    old_count = ticket.ticket_activities.count

    post login_path, params: {
      session: {
        email: admin.email,
        password: "password123"
      }
    }

    patch update_priority_ticket_path(ticket), params: {
      priority: old_priority
    }

    assert_equal old_count, ticket.ticket_activities.reload.count
    assert_equal old_priority, ticket.reload.priority
  end


  test "successful status change creates an activity record" do
    engineer = users(:engineer)
    ticket = tickets(:open_ticket)

    post login_path, params: {
      session: {
        email: engineer.email,
        password: "password123"
      }
    }

    old_count = ticket.ticket_activities.count

    patch update_status_ticket_path(ticket), params: {
      status: "in_progress"
    }

    assert_redirected_to ticket_path(ticket)
    assert_equal "in_progress", ticket.reload.status
    assert_equal old_count + 1, ticket.ticket_activities.reload.count
  end

  test "failed status change does not create an activity record" do
    requester = users(:requester)
    ticket = tickets(:open_ticket)
    old_count = ticket.ticket_activities.count

    post login_path, params: {
      session: {
        email: requester.email,
        password: "password123"
      }
    }

    patch update_status_ticket_path(ticket), params: {
      status: "in_progress"
    }

    assert_redirected_to ticket_path(ticket)
    assert_equal "open", ticket.reload.status
    assert_equal old_count, ticket.ticket_activities.reload.count
  end

end
