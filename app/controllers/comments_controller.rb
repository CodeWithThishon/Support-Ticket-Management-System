class CommentsController < ApplicationController
  def create
    @ticket = Ticket.find(params[:ticket_id])

    unless @ticket.commentable_by?(current_user)
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
end
