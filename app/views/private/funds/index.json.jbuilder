json.current_user @current_user
json.deposit_channels @deposit_channels
json.withdraw_channels @withdraw_channels
json.currencies @currencies
json.deposits @deposits
json.accounts @accounts
json.withdraws @withdraws
json.fund_sources @fund_sources
json.banks @banks.map(&:attributes), :code
json.fees @fees
json.bank_account @bank_account
json.member_setting @member_setting
json.deposit_mode @deposit_mode
json.security @security
