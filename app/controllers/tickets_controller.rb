class TicketsController < ApplicationController
  before_action :require_requester, only: [:new, :create]


  def index
    @tickets =
      case current_user.role
      when "admin"
        Ticket.all
      when "engineer"
        current_user.assigned_tickets
      when "requester"
        current_user.requested_tickets
      else
        Ticket.none
      end

    if params[:search].present?
      search = "%#{params[:search].strip}%"
      @tickets = @tickets.where(
        "ticket_number ILIKE :search OR title ILIKE :search",
        search: search
      )
    end

    if params[:status].present? && Ticket::STATUSES.include?(params[:status])
      @tickets = @tickets.where(status: params[:status])
    end

    if params[:priority].present? && Ticket::PRIORITIES.include?(params[:priority])
      @tickets = @tickets.where(priority: params[:priority])
    end

    if current_user.role == "admin"
      if params[:assignee_id].present?
        @tickets = @tickets.where(assignee_id: params[:assignee_id])
      end

      if params[:requester_id].present?
        @tickets = @tickets.where(requester_id: params[:requester_id])
      end

      if params[:unassigned] == "1"
        @tickets = @tickets.where(assignee_id: nil)
      end
    end

    case params[:sort]
    when "oldest"
      @tickets = @tickets.order(created_at: :asc)
    when "priority"
      @tickets = @tickets.order(
        Arel.sql(
          "CASE priority " \
            "WHEN 'critical' THEN 1 " \
            "WHEN 'high' THEN 2 " \
            "WHEN 'medium' THEN 3 " \
            "WHEN 'low' THEN 4 END"
        )
      )
    when "updated"
      @tickets = @tickets.order(updated_at: :desc)
    else
      @tickets = @tickets.order(created_at: :desc)
    end

    @engineers = User.where(role: "engineer").order(:name) if current_user.role == "admin"
    @requesters = User.where(role: "requester").order(:name) if current_user.role == "admin"
  end


  def new
     @ticket = Ticket.new
  end

  def show
     @ticket = Ticket.find(params[:id])

     unless view_tickets?(@ticket)
       flash[:danger] = "Not Authorized"
       redirect_to tickets_path
     end
  end


  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.requester = current_user

    begin
      Ticket.transaction do
        @ticket.save!

        activity = TicketActivity.new(
          ticket: @ticket,
          user: current_user,
          action: "created",
          details: "Ticket #{@ticket.ticket_number} was created"
        )

        activity.save!
      end

      flash[:success] = "Ticket created!"
      redirect_to tickets_path

    rescue ActiveRecord::RecordInvalid
      flash[:danger] = "Ticket could not be created or its activity could not be logged."
      render 'new'
    end
  end

  def assign
    @ticket = Ticket.find(params[:id])

    unless current_user.role == "admin"
      redirect_to ticket_path(@ticket),
                  alert: "Only admins can assign tickets."
      return
    end

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

    unless current_user.role == "admin"
      flash[:danger] = "Only admins can change ticket priority."
      redirect_to ticket_path(@ticket)
      return
    end

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
      flash[:danger] = "Only Requesters can create tickets."
      redirect_to tickets_path
    end

    def view_tickets?(ticket)
      case current_user.role
      when "admin"
        true
      when "engineer"
        ticket.assignee_id == current_user.id
      when "requester"
        ticket.requester_id == current_user.id
      end
    end
end
