module Admin
  module Deposits
    class BanksController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Bank'

      def index
        @allday_banks = @banks.includes(:member).
          order('id DESC')

        @available_banks = @banks.includes(:member).
          with_aasm_state(:submitting, :warning, :submitted).
          order('id DESC')

        @allday_banks -= @available_banks

      end

      def new
        @bank = Deposit.new
      end

      def create
        if Member.exists?(:sn_code => params[:deposit][:sn_code])
          member = Member.find_by_sn_code(params[:deposit][:sn_code])
          account = member.accounts.find_by_currency(1)
          currency = "jpy"
          type = "Deposits::Bank"
          @bank = Deposit.new(:amount => params[:deposit][:amount], :currency => currency, :account_id => account.id, :member_id => member.id, :type => type)
          redirect_to admin_deposits_bank_confirm_path(code: params[:deposit][:sn_code], amount: params[:deposit][:amount])
        else
          flash[:alert] = t('.member_not_found')
          render :new
        end
      end

			def confirm_deposit_yen
				@amount = params[:amount]
				@code = params[:code]
        if @code.nil?
          render :new
        else
  				@deposit_member = Member.includes(:bank_account).find_by(sn_code: @code)
          @document_id = IdDocument.find_by_member_id(@deposit_member.id)
          if !@deposit_member.nil?
            if @deposit_member.bank_account.nil?
              flash[:alert] = t('.bank_account_empty')
              render :new
            elsif @deposit_member.display_name.nil?
              @name = IdDocument.where(member_id: @deposit_member.id).first.name
            else
              @name = @deposit_member.display_name
            end
          else
            flash[:alert] = t('.member_not_found')
            render :new
          end
        end
			end

			def create_deposit_yen
				if Member.exists?(:sn_code => params[:deposit][:sn_code])
					member = Member.find_by_sn_code(params[:deposit][:sn_code])
					account = member.accounts.find_by_currency(1)
					currency = "jpy"
					type = "Deposits::Bank"
					@bank = Deposit.new(:amount => params[:deposit][:amount], :currency => currency, :account_id => account.id, :member_id => member.id, :type => type)
					if @bank.save
						redirect_to admin_deposits_banks_path, :flash => { :notice => "日本円を反映させるために、保留中のリクエストを承認してください"}
					else
						redirect_to new_admin_deposits_bank_path, :flash => { :alert => "FAILS" }
					end
				else
					redirect_to new_admin_deposits_bank_path, :flash => { :alert => "FAILS" }
				end
			end

      def show
        flash.now[:notice] = t('.notice') if @bank.aasm_state.accepted?
      end

      def update
				#unuse ixid -> set default is 1
        @bank.charge!(1)
        redirect_to :back
      end

      private
      def target_params
        params.require(:deposits_bank).permit(:sn, :holder, :amount, :created_at)
      end

      def deposit_params
        params.require(:deposit).permit(:id, :amount)
      end
    end
  end
end
