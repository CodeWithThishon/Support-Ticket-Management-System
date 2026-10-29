class CommentsController < ApplicationController
  def create
    @ticket = Ticket.find(params[:ticket_id])

    unless can_comment_on?(@ticket)
      redirect_to tickets_path,
                  alert: "You are not authorized to comment on this ticket."
      return
    end

    @comment = @ticket.ticket_comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to ticket_path(@ticket),
                  notice: "Comment added successfully."
    else
      redirect_to ticket_path(@ticket),
                  alert: "Comment cannot be empty."
    end
  end

  private

  def comment_params
    params.require(:ticket_comment).permit(:body)
  end

  def can_comment_on?(ticket)
    case current_user.role
    when "admin"
      true
    when "engineer"
      ticket.assignee_id == current_user.id
    when "requester"
      ticket.requester_id == current_user.id
    else
      false
    end
  end
end