module Concerns
  module OrderCreation
    extend ActiveSupport::Concern

    DAY_ORDER_LIMIT = 50000
    MONTH_ORDER_LIMIT = 250000

    def gate_level1!
      if current_user.account_class == 1
        respond_to do |format|
          flash[:notice] = I18n.t('private.settings.index.auth-verified')
          format.js {render :js => "window.location.href='"+settings_path+"'"}
        end
        return false
      end
    end

    def gate_level2!
      if current_user.account_class == 2
        sum_current_day_order = 0
        sum_current_month_order = 0
        if params["order_ask"]
          all_order = current_user.orders.where("ask = 1  and state != 0")
          this_order = order_params(:order_ask)[:volume].to_f * order_params(:order_ask)[:price].to_f
        else
          all_order = current_user.orders.where("bid = 1  and state != 0")
          this_order = order_params(:order_bid)[:volume].to_f * order_params(:order_bid)[:price].to_f
        end

        if params[:market].index("jpy")
          current_day_order = all_order.where('extract(day from created_at) = ? AND extract(month from created_at) = ? AND extract(year from created_at) = ?', Date.today.day, Date.today.month, Date.today.year)
          current_month_order = all_order.where('extract(month from created_at) = ? AND extract(year from created_at) = ?', Date.today.month, Date.today.year)

          current_day_order.each { |order|
            sum_current_day_order += order[:price].to_f * order[:origin_volume].to_f
          }

          current_month_order.each { |order|
            sum_current_month_order += order[:price].to_f * order[:origin_volume].to_f
          }

          sum_current_day_order += this_order
          sum_current_month_order += this_order
        end

        if sum_current_day_order > DAY_ORDER_LIMIT || sum_current_month_order > MONTH_ORDER_LIMIT
          respond_to do |format|
            flash[:alert] = I18n.t('private.settings.index.upgrade_account')
            format.js {render :js => "window.location.href='"+settings_path+"'"}
          end
          return false
        end
      end
    end

    def order_params(order)
      params[order][:bid] = params[:bid]
      params[order][:ask] = params[:ask]
      params[order][:state] = Order::WAIT
      params[order][:currency] = params[:market]
      params[order][:member_id] = current_user.id
      params[order][:volume] = params[order][:origin_volume]
      params[order][:source] = 'Web'
      params.require(order).permit(
        :bid, :ask, :currency, :price, :source,
        :state, :origin_volume, :volume, :member_id, :ord_type)
    end

    def order_submit
      begin
        Ordering.new(@order).submit currency
        render status: 200, json: success_result
      rescue
        Rails.logger.warn "Member id=#{current_user.id} failed to submit order: #{$!}"
        Rails.logger.warn params.inspect
        Rails.logger.warn $!.backtrace[0,20].join("\n")
        render status: 500, json: error_result(@order.errors)
      end
    end

    def success_result
      Jbuilder.encode do |json|
        json.result true
        json.message I18n.t("private.markets.show.success")
      end
    end

    def error_result(args)
      Jbuilder.encode do |json|
        json.result false
        message = if !args.messages[:amount].nil?
                    args.messages[:amount].first
                  else
                    I18n.t("private.markets.show.error")
                  end
        json.message message
        json.errors args
      end
    end
  end
end
