class DepositInfomation < ActiveRecord::Base
  include AASM
  include AASM::Locking

  validates_presence_of :payer_name, :amount, :date_deposit, :user_id
  belongs_to :member
  aasm do
    state :verifying, initial: true
    state :unverified
    state :verified

    event :approve do
      transitions from: [:unverified, :verifying],  to: :verified
    end

    event :reject do
      transitions from: [:verifying, :verified],  to: :unverified
    end
  end

  class << self
    def search(field: nil, term: nil)
      result = case field
               when 'email'
                 joins(:member).where('members.is_lock' => nil).where('members.email LIKE ?', "%#{term}%")
               when 'id'
                 joins(:member).where('members.is_lock' => nil).where('member_id = ?', "#{term}")
               when 'name'
                 where("payer_name = ?", "#{term}")
               else
                 joins(:member).merge(Member.avail_member)
               end

      result.order(id: :desc)
    end
  end
end
