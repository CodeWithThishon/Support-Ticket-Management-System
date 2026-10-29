
require 'test_helper'

class TicketTest < ActiveSupport::TestCase

  test "ticket fixtures are valid" do
    assert tickets(:open_ticket).valid?
    assert tickets(:resolved_ticket).valid?
  end

  test "ticket requires a title" do
    ticket = tickets(:open_ticket)
    ticket.title = nil
    assert_not ticket.valid?
  end

  test "ticket requires a description" do
    ticket = tickets(:open_ticket)
    ticket.description = nil
    assert_not ticket.valid?
  end

  test "ticket priority must be valid" do
    ticket = tickets(:open_ticket)
    ticket.priority = "urgent"
    assert_not ticket.valid?
  end

  test "ticket status must be valid" do
    ticket = tickets(:open_ticket)
    ticket.status = "pending"
    assert_not ticket.valid?
  end

  test "ticket number must be unique" do
    ticket = Ticket.new(
      ticket_number: tickets(:open_ticket).ticket_number,
      title: "Another ticket",
      description: "Testing duplicate ticket numbers.",
      requester: users(:requester),
      priority: "medium",
      status: "open"
    )
    assert_not ticket.valid?
  end


  test "assigned engineer can start working on a ticket" do
    ticket = tickets(:open_ticket)
    engineer = users(:engineer)

    assert ticket.change_status("in_progress", user: engineer)
    assert_equal "in_progress", ticket.status
  end

  test "assigned engineer can resolve a ticket with a summary" do
    ticket = tickets(:open_ticket)
    engineer = users(:engineer)

    assert ticket.change_status(
      "in_progress",
      user: engineer
    )

    assert ticket.change_status(
      "resolved",
      user: engineer,
      summary: "Login issue fixed."
    )

    assert_equal "resolved", ticket.status
    assert_equal "Login issue fixed.", ticket.resolution_summary
    assert_not_nil ticket.resolved_at
  end

  test "engineer cannot resolve a ticket without a summary" do
    ticket = tickets(:open_ticket)
    engineer = users(:engineer)

    ticket.change_status("in_progress", user: engineer)

    assert_not ticket.change_status(
      "resolved",
      user: engineer,
      summary: ""
    )
  end

  test "requester can reopen their resolved ticket" do
    ticket = tickets(:resolved_ticket)
    requester = users(:requester)
    assert ticket.change_status("open", user: requester)
    assert_equal "open", ticket.status
    assert_nil ticket.resolved_at
  end

  test "requester can close their resolved ticket" do
    ticket = tickets(:resolved_ticket)
    requester = users(:requester)
    assert ticket.change_status("closed", user: requester)
    assert_equal "closed", ticket.status
    assert_not_nil ticket.closed_at
  end

  test "requester cannot start working on a ticket" do
    ticket = tickets(:open_ticket)
    requester = users(:requester)
    assert_not ticket.change_status("in_progress", user: requester)
    assert_equal "open", ticket.status
  end

  test "closed ticket cannot be reopened" do
    ticket = tickets(:resolved_ticket)
    requester = users(:requester)
    assert ticket.change_status("closed", user: requester)
    assert_not ticket.change_status("open", user: requester)
    assert_equal "closed", ticket.status
  end


  test "ticket can be unassigned" do
    ticket = tickets(:open_ticket)
    ticket.assignee = nil
    assert ticket.valid?
    assert_nil ticket.assignee
  end

  test "ticket requires a requester" do
    ticket = tickets(:open_ticket)
    ticket.requester = nil
    assert_not ticket.valid?
  end

  test "ticket can be assigned to an engineer" do
    ticket = tickets(:open_ticket)
    ticket.assignee = users(:engineer)
    assert ticket.valid?
    assert_equal users(:engineer).id, ticket.assignee_id
  end


  test "unassigned engineer cannot start working on a ticket" do
    ticket = tickets(:open_ticket)
    other_engineer = User.create!(
      name: "Other Engineer",
      email: "other_engineer@example.com",
      password: "password123",
      role: "engineer"
    )
    assert_not ticket.change_status(
      "in_progress",
      user: other_engineer
    )
    assert_equal "open", ticket.status
  end
end
