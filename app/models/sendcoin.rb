class Sendcoin < ActiveRecord::Base
  belongs_to :member
  has_many :currencies
  #accepts_nested_attributes_for :member
  validates_numericality_of :amount, :greater_than => 0
  validates_presence_of :amount
  validate :round_amount_to_zero
  validates :email, presence: true

  private
  def round_amount_to_zero
    if amount.to_f.round(3) == 0
    errors.add(:amount, I18n.t('private.sendcoin.create.round_amout'))
  end
end

end
