require 'test_helper'
class CommentsControllerTest < ActionDispatch::IntegrationTest

  test "requester can comment on their own ticket" do
    requester = users(:requester)
    ticket = tickets(:open_ticket)

    post login_path, params: {
      session: {
        email: requester.email,
        password: "password123"
      }
    }

    assert_difference "TicketComment.count", 1 do
      post ticket_comments_path(ticket), params: {
        ticket_comment: { body: "I am still experiencing this issue." }
      }
    end

    assert_redirected_to ticket_path(ticket)
    assert_equal requester.id, TicketComment.last.user_id
    assert_equal ticket.id, TicketComment.last.ticket_id
  end

  test "unauthenticated user cannot comment" do
    ticket = tickets(:open_ticket)

    assert_no_difference "TicketComment.count" do
      post ticket_comments_path(ticket), params: {
        ticket_comment: { body: "Unauthorized comment" }
      }
    end

    assert_redirected_to login_path
  end

  test "unauthorized requester cannot comment on another requester's ticket" do
    other_requester = User.create!(
      name: "Other Requester",
      email: "other_requester@example.com",
      password: "password123",
      role: "requester"
    )
    ticket = tickets(:open_ticket)
    post login_path, params: {
      session: {
        email: other_requester.email,
        password: "password123"
      }
    }
    assert_no_difference "TicketComment.count" do
      post ticket_comments_path(ticket), params: {
        ticket_comment: {
          body: "I should not be able to comment here."
        }
      }
    end
  end

end
