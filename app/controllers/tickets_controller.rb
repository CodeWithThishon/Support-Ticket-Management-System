class TicketsController < ApplicationController
  before_action :require_requester, only: [:new, :create]
  before_action :require_admin, only: [:assign, :update_priority]

  def index
    @tickets = Ticket.visible_to(current_user)
                     .search(params[:search])
                     .filter_by(params, admin: current_user.role == "admin")
                     .ordered_by(params[:sort])
                     .paginate(page: params[:page], per_page: 10)

    if current_user.role == "admin"
      @engineers = User.where(role: "engineer").order(:name)
      @requesters = User.where(role: "requester").order(:name)
    end
  end

  def new
    @ticket = Ticket.new
  end

  def show
    @ticket = Ticket.includes(:requester, :assignee).find(params[:id])

    unless @ticket.visible_to?(current_user)
      redirect_to tickets_path, alert: "Not authorized to view this ticket."
      return
    end

    @engineers = User.where(role: "engineer").order(:name) if current_user.role == "admin"
  end

  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.requester = current_user

    begin
      Ticket.transaction do
        @ticket.save!

        TicketActivity.create!(
          ticket: @ticket,
          user: current_user,
          action: "created",
          details: "Ticket #{@ticket.ticket_number} was created"
        )
      end

      flash[:success] = "Ticket created!"
      redirect_to tickets_path

    rescue ActiveRecord::RecordInvalid
      flash[:danger] = "Ticket could not be created or its activity could not be logged."
      render :new
    end
  end

  def assign
    @ticket = Ticket.find(params[:id])

    assignee_id = params[:assignee_id]
    old_assignee_id = @ticket.assignee_id

    if assignee_id.blank?
      new_assignee_id = nil
    else
      engineer = User.find_by(id: assignee_id, role: "engineer")

      unless engineer
        redirect_to ticket_path(@ticket),
                    alert: "Select a valid engineer!"
        return
      end

      new_assignee_id = engineer.id
    end

    if old_assignee_id == new_assignee_id
      redirect_to ticket_path(@ticket),
                  notice: "No assignment changes were made."
      return
    end

    begin
      Ticket.transaction do
        @ticket.update!(assignee_id: new_assignee_id)

        TicketActivity.create!(
          ticket: @ticket,
          user: current_user,
          action: "assigned",
          details: "Ticket assignment updated."
        )
      end

      flash[:success] = "Ticket assignment updated successfully."
    rescue ActiveRecord::RecordInvalid
      flash[:danger] = "Assignment failed. No changes were saved."
    end

    redirect_to ticket_path(@ticket)
  end

  def update_status
    @ticket = Ticket.find(params[:id])
    new_status = params[:status]
    old_status = @ticket.status

    begin
      Ticket.transaction do
        unless @ticket.change_status(
          new_status,
          user: current_user,
          summary: params[:resolution_summary]
        )
          raise ActiveRecord::Rollback
        end

        if @ticket.status != old_status
          TicketActivity.create!(
            ticket: @ticket,
            user: current_user,
            action: "status_changed",
            details: "Ticket status changed from #{old_status} to #{@ticket.status}."
          )
        end
      end

      if @ticket.errors.any?
        flash[:danger] = @ticket.errors.full_messages.to_sentence
      else
        flash[:success] = "Ticket status updated successfully."
      end

    rescue ActiveRecord::RecordInvalid
      flash[:danger] = "Status update failed. No changes were saved."
    end

    redirect_to ticket_path(@ticket)
  end

  def update_priority
    @ticket = Ticket.find(params[:id])

    new_priority = params[:priority]
    old_priority = @ticket.priority

    if old_priority == new_priority
      flash[:success] = "No priority changes were made."
      redirect_to ticket_path(@ticket)
      return
    end

    unless Ticket::PRIORITIES.include?(new_priority)
      flash[:danger] = "Please select a valid priority."
      redirect_to ticket_path(@ticket)
      return
    end

    begin
      Ticket.transaction do
        @ticket.update!(priority: new_priority)

        TicketActivity.create!(
          ticket: @ticket,
          user: current_user,
          action: "priority_changed",
          details: "Priority changed from #{old_priority} to #{new_priority}."
        )
      end

      flash[:success] = "Ticket priority updated successfully."
    rescue ActiveRecord::RecordInvalid
      flash[:danger] = "Priority update failed. No changes were saved."
    end

    redirect_to ticket_path(@ticket)
  end

  private

  def ticket_params
    params.require(:ticket).permit(:title, :description, :priority)
  end

  def require_requester
    return if current_user.role == "requester"

    redirect_to tickets_path, alert: "Only requesters can create tickets."
  end

  def require_admin
    return if current_user.role == "admin"

    redirect_to ticket_path(params[:id]), alert: "Only admins can perform this action."
  end
end
