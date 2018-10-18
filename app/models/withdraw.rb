class Withdraw < ActiveRecord::Base
  STATES = [:submitting, :submitted, :rejected, :accepted, :suspect, :processing,
            :done, :canceled, :almost_done, :failed]
  COMPLETED_STATES = [:done, :rejected, :canceled, :almost_done, :failed]

  extend Enumerize

  include AASM
  include AASM::Locking
  include Currencible

  has_paper_trail on: [:update, :destroy]

  enumerize :aasm_state, in: STATES, scope: true

  belongs_to :member
  belongs_to :account
  belongs_to :bank_account
  has_many :account_versions, as: :modifiable

  delegate :balance, to: :account, prefix: true
  delegate :key_text, to: :channel, prefix: true
  delegate :id, to: :channel, prefix: true
  delegate :name, to: :member, prefix: true
  delegate :coin?, :fiat?, to: :currency_obj

  before_validation :fix_precision
  before_validation :calc_fee
  before_validation :set_account
  after_create :generate_sn

  after_update :sync_update
  after_create :sync_create
  after_destroy :sync_destroy

  validates_with WithdrawBlacklistValidator

  validates :fund_uid, :amount, :fee, :account, :currency, :member, presence: true

  validates :fee, numericality: {greater_than_or_equal_to: 0}
  validates :amount, numericality: {greater_than: 0}

  validates :sum, presence: true, numericality: {greater_than: 0}, on: :create
  validates :txid, uniqueness: true, allow_nil: true, on: :update

  validate :ensure_account_balance, on: :create

  scope :completed, -> { where aasm_state: COMPLETED_STATES }
  scope :not_completed, -> { where.not aasm_state: COMPLETED_STATES }

  def self.channel
    WithdrawChannel.find_by_key(name.demodulize.underscore)
  end

  def channel
    self.class.channel
  end

  def channel_name
    channel.key
  end

  alias_attribute :withdraw_id, :sn
  alias_attribute :full_name, :member_name

  def generate_sn
    id_part = sprintf '%04d', id
    date_part = created_at.localtime.strftime('%y%m%d%H%M')
    self.sn = "#{date_part}#{id_part}"
    update_column(:sn, sn)
  end

  aasm :whiny_transitions => false do
    state :submitting,  initial: true
    state :submitted,   after_commit: :send_email
    state :canceled,    after_commit: [:send_email]
    state :accepted
    state :suspect,     after_commit: :send_email
    state :rejected,    after_commit: :send_email
    state :processing,  after_commit: [:send_coins!, :send_email]
    state :almost_done
    state :done,        after_commit: [:send_email]
    state :failed,      after_commit: :send_email

    event :submit do
      transitions from: :submitting, to: :submitted
      after do
        lock_funds
      end
    end

    event :cancel do
      transitions from: [:submitting, :submitted, :accepted], to: :canceled
      after do
        after_cancel
      end
    end

    event :mark_suspect do
      transitions from: :submitted, to: :suspect

      after :unlock_funds
    end

    event :accept do
      transitions from: :submitted, to: :accepted
    end

    event :reject do
      transitions from: [:submitted, :accepted, :processing], to: :rejected
      after :unlock_funds
    end

    event :process do
      transitions from: :accepted, to: :processing
    end

    event :call_rpc do
      transitions from: :processing, to: :almost_done
    end

    event :succeed do
      transitions from: [:processing, :almost_done], to: :done

      before [:set_txid, :unlock_and_sub_funds]
    end

		event :success_jpy do
			transitions from: [:accepted, :processing, :almost_done], to: :done

      before [:set_txid, :unlock_and_sub_funds]
		end

    event :error do
      transitions from: :almost_done, to: :rejected

      after :unlock_funds
    end

    event :fail do
      transitions from: :processing, to: :failed
    end
  end

  def cancelable?
    submitting? or submitted? or accepted?
  end

  def quick?
    if [16, 98].include?(member.id)
      return true
    end
    sum <= currency_obj.quick_withdraw_max
  end

  def audit!
    with_lock do
      if account.examine
        accept
        if quick?
          process!
          #post slack
          begin
            notifier = Slack::Notifier.new(Rails.application.config.slack_webhook_url)
            message = {
              "text": "#{name} Withdraw #{currency} with amount:#{amount} by id: #{id} processing!!!"
            }
            notifier.ping(message)

          rescue StandardError => bang
            puts "Slack notify error"
          end
        else
          if currency != 'jpy'
            #post slack
            begin
              notifier = Slack::Notifier.new(Rails.application.config.slack_webhook_url)
              message = {
                "text": "ERROR, #{name} withdraw #{currency} with amount:#{amount} by id #{id} greater than quick withdraw max!!!"
              }
              notifier.ping(message)

            rescue StandardError => bang
              puts "Slack notify error"
            end
          else
            #post slack
            begin
              notifier = Slack::Notifier.new(Rails.application.config.slack_webhook_url)
              message = {
                "text": "Withdraw JPY id #{id}"
              }
              notifier.ping(message)

            rescue StandardError => bang
              puts "Slack notify error"
            end
          end
        end
      else
        mark_suspect
      end

      save!
    end
  end

  private

  def after_cancel
    unlock_funds unless aasm.from_state == :submitting
  end

  def lock_funds
    account.lock!
    account.lock_funds sum, reason: Account::WITHDRAW_LOCK, ref: self
  end

  def unlock_funds
    account.lock!
    if self.currency == 'kbr'
      account_user_eth = member.accounts.find_by_currency(4)
      account_user_eth.lock!.unlock_funds 0.005, reason: Account::WITHDRAW_KBR, ref: self
    end
    account.unlock_funds sum, reason: Account::WITHDRAW_UNLOCK, ref: self
  end

  def unlock_and_sub_funds
    account.lock!
    account.unlock_and_sub_funds sum, locked: sum, fee: fee, reason: Account::WITHDRAW, ref: self
  end

  def set_txid
    self.txid = @sn unless coin?
  end

  def send_email
    return unless member.security.send_email["Withdraw"]
    case aasm_state
    when 'submitted'
      WithdrawMailer.submitted(self.id).deliver
    when 'done'
      WithdrawMailer.done(self.id).deliver
    end
  end

  def send_sms
    return true if not member.sms_two_factor.activated?

    sms_message = I18n.t('sms.withdraw_done', email: member.email,
                                              currency: currency_text,
                                              time: I18n.l(Time.now),
                                              amount: amount,
                                              balance: account.balance)

    AMQPQueue.enqueue(:sms_notification, phone: member.phone_number, message: sms_message)
  end

  def send_coins!
    if channel.currency == 'xrp'
      AMQPQueue.enqueue(:withdraw_ripple, id: id) if coin?
    elsif channel.currency == 'eth'
      AMQPQueue.enqueue(:withdraw_eth, id: id) if coin?
    elsif channel.currency == 'etc'
      AMQPQueue.enqueue(:withdraw_etc, id: id) if coin?
    elsif channel.currency == 'kbr'
      AMQPQueue.enqueue(:withdraw_kbr, id: id) if coin?
    else
      AMQPQueue.enqueue(:withdraw_coin, id: id) if coin?
    end
  end

  def ensure_account_balance
    if self.currency == "jpy"
      if self.sum < 30000
        if sum.nil? or (sum + 432) > account.balance
          errors.add :base, -> { I18n.t('activerecord.errors.models.withdraw.account_balance_is_poor') }
        end
      else
        if sum.nil? or (sum + 648) > account.balance
          errors.add :base, -> { I18n.t('activerecord.errors.models.withdraw.account_balance_is_poor') }
        end
      end
    elsif self.currency == 'kbr'
      if sum > account.balance
        errors.add :base, -> { I18n.t('activerecord.errors.models.withdraw.account_balance_is_poor') }
      end
    else
      if sum.nil? or (sum + FeeTrade.find_by(currency: self.currency.value).amount.to_f) > account.balance
        errors.add :base, -> { I18n.t('activerecord.errors.models.withdraw.account_balance_is_poor') }
      end
    end
  end

  def fix_precision
    if sum && currency_obj.precision
      self.sum = sum.round(currency_obj.precision, BigDecimal::ROUND_DOWN)
    end
  end

  def calc_fee
    if respond_to?(:set_fee)
      set_fee
    end
    if self.currency == "jpy"
      self.sum ||= 0.0
      self.fee ||= 0.0
      if self.submitted?
        self.fee = FeeTrade.find_by(:currency => 1).amount.to_f
        if self.sum < 30000
          self.fee = 432
        else
          self.fee = 648
        end
        self.sum = self.sum + fee
      end
      self.amount = sum - fee
    else
      self.sum ||= 0.0
      self.fee ||= 0.0
      self.amount = sum - fee
    end
  end

  def set_account
    self.account = member.get_account(currency)
  end

  def self.resource_name
    name.demodulize.underscore.pluralize
  end

  def sync_update
    ::Pusher["private-#{member.sn}"].trigger_async('withdraws', { type: 'update', id: self.id, attributes: self.changes_attributes_as_json })
  end

  def sync_create
    ::Pusher["private-#{member.sn}"].trigger_async('withdraws', { type: 'create', attributes: self.as_json })
  end

  def sync_destroy
    ::Pusher["private-#{member.sn}"].trigger_async('withdraws', { type: 'destroy', id: self.id })
  end


end
