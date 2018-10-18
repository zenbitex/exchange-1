class ArbMailer < BaseMailer
  def send_profit(member_id, profit)
    member = Member.find(member_id)
    @profit = profit
    mail to: member.email
  end
end