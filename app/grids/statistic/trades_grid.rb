module Statistic
  class TradesGrid
    include Datagrid
    include Datagrid::Naming
    include Datagrid::ColumnI18n

    scope do
      Trade.order('created_at DESC')
    end

    filter(:currency, :enum, :select => Trade.currency.value_options, :default => 3, :include_blank => false)
    filter(:created_at, :datetime, :range => true, :default => proc { [1.day.ago, Time.now]})

    column(:ask_member_id, :order => nil, html: true) do |record|
        link_to Member.find(record.ask_member_id).email, admin_member_path(record.ask_member_id)
    end
    column(:bid_member_id, :order => nil, html: true) do |record|
        link_to Member.find(record.bid_member_id).email, admin_member_path(record.bid_member_id)
    end
    column(:price)
    column(:volume)
    column(:strike_amount) { price * volume }
    column_localtime :created_at
    column(:fee, :order => nil)
  end
end
