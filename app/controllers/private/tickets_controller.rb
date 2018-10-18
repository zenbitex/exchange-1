module Private
  class TicketsController < BaseController
    after_filter :mark_ticket_as_read, only: [:create, :show]

    def index
      @tickets = current_user.tickets
      @tickets_open = @tickets.open
      @tickets_close = @tickets.closed
      @unread = ticket_unread

      @tickets = params[:closed].nil? ? @tickets.open : @tickets.closed
      gon.jbuilder
    end

    def new
      @ticket = Ticket.new
    end

    def create
      @ticket = current_user.tickets.create(ticket_params)
      if @ticket.save
        flash[:notice] = I18n.t('private.tickets.ticket_create_succ')
        tickets = current_user.tickets
        render json: {
          tickets_open: tickets.open,
          tickets_closed: tickets.closed,
          unread: ticket_unread,
          ticket_id: @ticket.id,
          success: true,
          msg: I18n.t('private.tickets.ticket_create_succ')
        }
      else
        render json: {success: false, msg: I18n.t('private.tickets.ticket_create_fail')}
      end
    end

    def show
      @comments = ticket.comments
      @comments.unread_by(current_user).each do |c|
        c.mark_as_read! for: current_user
      end
      @comment = Comment.new

      respond_to do |format|
        format.html
        format.json {
          render json: {unread: ticket_unread, ticket: ticket, comments: @comments}
        }
      end
    end

    def close
      flash[:notice] = I18n.t('private.tickets.close_succ') if ticket.close!
      redirect_to tickets_path
    end

    private

    def ticket_unread
      unread = []
      tickets = current_user.tickets
      tickets.each do |t|
        if t.comments.unread_by(current_user).present?
          unread << t.id
        end
      end
      unread
    end

    def ticket_params
      params.required(:ticket).permit(:title, :content)
    end

    def ticket
      @ticket ||= current_user.tickets.find(params[:id])
    end

    def mark_ticket_as_read
      ticket.mark_as_read!(for: current_user) if ticket.unread?(current_user)
    end
  end
end
