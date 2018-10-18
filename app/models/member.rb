class Member < ActiveRecord::Base
  acts_as_taggable
  acts_as_reader

  has_many :orders
  has_many :accounts
  has_many :payment_addresses, through: :accounts
  has_many :withdraws
  has_many :fund_sources
  has_many :deposits
  has_many :api_tokens
  has_many :two_factors
  has_many :tickets, foreign_key: 'author_id'
  has_many :comments, foreign_key: 'author_id'
  has_many :signup_histories
  has_many :taocoin_trades
  has_many :arb_histories
  has_one :arb
  has_many :taocoin_exchanges
  has_one :id_document
  has_one :bank_account
  has_one :arb_profit
  has_many :deposit_infomations
  has_many :coin_trades
  has_one  :affiliate
  has_one :security
  has_many :account_versions
  has_many :tokens
  has_many :fcm_tokens

  has_many :authentications, dependent: :destroy

  scope :enabled, -> { where(disabled: false) }
  scope :avail_member, -> {where("is_lock != 1 or is_lock is null")}
  scope :by_ids, -> ids{where id: ids}
  scope :active, -> { where(activated: 1) }

  delegate :activated?, to: :two_factors, prefix: true, allow_nil: true
  delegate :name,       to: :id_document, allow_nil: true
  delegate :full_name,  to: :id_document, allow_nil: true
  delegate :verified?,  to: :id_document, prefix: true, allow_nil: true

  before_validation :sanitize, :generate_sn, :generate_sn_code

  validates :sn, presence: true
  validates :display_name, uniqueness: true, allow_blank: true
  validates :email, email: true, uniqueness: true, allow_nil: true

  before_create :build_default_id_document
  before_create :build_default_bank_account
  before_create :create_securities
  after_create  :touch_accounts
  after_update :resend_activation
  after_update :sync_update

  has_many :participations, dependent: :destroy
  has_many :chats, through: :participations, source: :chat

  has_many :owned_chats, class_name: 'Chat', foreign_key: 'owner_id'

  has_many :messages, class_name: 'Message', foreign_key: 'sent_id', dependent: :destroy

  def join_in chat
    self.participations.create(chat_id: chat.id)
  end

  def create_securities
    setting = {}
    Settings.list_settings.each do |key, value|
      setting[value] = true
    end
    create_security send_email: setting, two_factor: {"Withdraw"=> false, "Login"=> false}
  end

  def two_factor_login?
    security.two_factor["Login"]
  end

  def two_factor_withdraw?
    security.two_factor["Withdraw"]
  end

  def send_email_login?
    security.send_email["Login"]
  end

  def send_email_withdraw?
    security.send_email["Withdraw"]
  end

  def activated_both?
    two_factors.by_type("app").activated? && two_factors.by_type("sms").activated?
  end

  def deposit_sum(currency)
    Deposit.where("member_id = ? AND currency =? AND aasm_state=?",self.id ,currency, "accepted").sum("amount")
  end

  class << self
    def from_auth(auth_hash)
      locate_auth(auth_hash) || locate_email(auth_hash) || create_from_auth(auth_hash)
    end

    def current
      Thread.current[:user]
    end

    def current=(user)
      Thread.current[:user] = user
    end

    def admins
      arr = []
      email = Member.where(["role = ? or role = ? or role = ?", 1, 2, 3])
      email.each do |e|
        arr << e["email"]
      end

      arr += Figaro.env.admin.split(',')
    end

    def search(field: nil, term: nil)
      if term.present?
        trim_space_input = term.squish.delete(' ')
      else
        trim_space_input = term
      end
      result = case field
               when 'email'
                 where('members.email LIKE ?', "%#{term}%")
               when 'id'
                 where('members.id LIKE ?', "%#{term}%")
               when 'phone_number'
                 where('members.phone_number LIKE ?', "%#{term}%")
               when 'name'
                  joins(:id_document).where(' REPLACE(REPLACE(id_documents.name, "　", ""), " ", "") LIKE ?', "%#{trim_space_input}%")
               when 'wallet_address'
                 members = joins(:fund_sources).where('fund_sources.uid' => term)
                 if members.empty?
                  members = joins(:payment_addresses).where('payment_addresses.address' => term)
                 end
                 members
               else
                 all
               end
    end

    def create_bank_account
      build_bank_account
      true
    end

    private

    def locate_auth(auth_hash)
      Authentication.locate(auth_hash).try(:member)
    end

    def locate_email(auth_hash)
      return nil if auth_hash['info']['email'].blank?
      member = find_by_email(auth_hash['info']['email'])
      return nil unless member
      member.add_auth(auth_hash)
      member
    end

    def create_from_auth(auth_hash)
      member = create(email: auth_hash['info']['email'], nickname: auth_hash['info']['nickname'],
                      activated: false)
      member.add_auth(auth_hash)
      if auth_hash['provider'] == 'identity'
        member.send_activation
      else
        member.active!
      end
      member
    end
  end


  def create_auth_for_identity(identity)
    self.authentications.create(provider: 'identity', uid: identity.id)
  end

  def trades
    Trade.where('bid_member_id = ? OR ask_member_id = ?', id, id)
  end

  def active!
    update activated: true
  end

  def update_password(password)
    identity.update_attributes password: password, password_confirmation: password
    send_password_changed_notification
  end

  def admin?
    @is_admin ||= self.class.admins.include?(self.email)
  end

  def add_auth(auth_hash)
    authentications.build_auth(auth_hash).save
  end

  def trigger(event, data)
    AMQPQueue.enqueue(:pusher_member, {member_id: id, event: event, data: data})
  end

  def notify(event, data)
    ::Pusher["private-#{sn}"].trigger_async event, data
  end

  def to_s
    "#{name || email} - #{sn}"
  end

  def gravatar
    "//gravatar.com/avatar/" + Digest::MD5.hexdigest(email.strip.downcase) + "?d=retro"
  end

  def initial?
    name? and !name.empty?
  end

  def get_account(currency)
    account = accounts.with_currency(currency.to_sym).first

    if account.nil?
      touch_accounts
      account = accounts.with_currency(currency.to_sym).first
    end

    account
  end
  alias :ac :get_account

  def touch_accounts
    less = Currency.codes - self.accounts.map(&:currency).delete_if{|i| i.nil?}.map(&:to_sym)
    less.each do |code|
      self.accounts.create(currency: code, balance: 0, locked: 0)
    end
  end

  def identity
    authentication = authentications.find_by(provider: 'identity')
    authentication ? Identity.find(authentication.uid) : nil
  end

  def auth(name)
    authentications.where(provider: name).first
  end

  def auth_with?(name)
    auth(name).present?
  end

  def remove_auth(name)
    identity.destroy if name == 'identity'
    auth(name).destroy
  end

  def send_activation
    Token::Activation.create(member: self)
  end

  def send_mail_activation
    Token::ActivationEmail.create(member: self)
  end

  def send_password_changed_notification
    MemberMailer.reset_password_done(self.id).deliver

    if sms_two_factor.activated?
      sms_message = I18n.t('sms.password_changed', email: self.email)
      AMQPQueue.enqueue(:sms_notification, phone: phone_number, message: sms_message)
    end
  end

  def unread_comments
    ticket_ids = self.tickets.open.collect(&:id)
    if ticket_ids.any?
      Comment.where(ticket_id: [ticket_ids]).where("author_id <> ?", self.id).unread_by(self).to_a
    else
      []
    end
  end

  def app_two_factor
    two_factors.by_type(:app)
  end

  def sms_two_factor
    two_factors.by_type(:sms)
  end

  def as_json(options = {})
    super(options).merge({
      "name" => self.name,
      "app_activated" => self.app_two_factor.activated?,
      "sms_activated" => self.sms_two_factor.activated?,
      "memo" => self.id
    })
  end

  private

  def sanitize
    self.email.try(:downcase!)
  end

  def generate_sn
    self.sn and return
    begin
      self.sn = "EXCHAN#{ROTP::Base32.random_base32(8).upcase}GEPRO"
    end while Member.where(:sn => self.sn).any?
  end

  def generate_sn_code
    self.sn_code and return
    begin
      self.sn_code = '%06d' % SecureRandom.random_number(1000000)
    end while Member.where(:sn_code => self.sn_code).any?
  end

  def build_default_id_document
    build_id_document
    true
  end

  def build_default_bank_account
    build_bank_account
    true
  end

  def resend_activation
    self.send_activation if self.email_changed?
  end

  def sync_update
    ::Pusher["private-#{sn}"].trigger_async('members', { type: 'update', id: self.id, attributes: self.changes_attributes_as_json })
  end
end
