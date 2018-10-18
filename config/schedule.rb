  # whenever -i --set environment='production'
  # whenever -i --set environment='development'
  # whenever -i --set environment='staging'
env :PATH, ENV['PATH']
set :output, 'log/cron_log.log'

# RUNNER
job_type :runner_kraken_btcjpy, "cd :path && flock -n /var/lock/:kraken_btcjpy.lock bin/rails runner -e :environment ':task' :output"
job_type :runner_kraken_xrpjpy, "cd :path && flock -n /var/lock/:kraken_xrpjpy.lock bin/rails runner -e :environment ':task' :output"
job_type :runner_kraken_xrpbtc, "cd :path && flock -n /var/lock/:kraken_xrpbtc.lock bin/rails runner -e :environment ':task' :output"
job_type :runner_cancel, "cd :path && bin/rails runner -e :environment ':task' :output"

# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# every 1.hours do
#   command '/usr/local/rbenv/shims/backup perform -t database_backup'
# end
#
# every :day, at: '4am' do
#   rake 'solvency:clean solvency:liability_proof'
# end
# set :environment, 'development'

every :day, at: '1am' do
  runner_cancel "CronJob::CancelOrderMarket.handle"
end

every 1.minute do
  # runner_kraken_btcjpy 'CronJob::KrakenJob.update_price_btcjpy'
  # runner_kraken_xrpjpy 'CronJob::KrakenJob.update_price_xrpjpy'
  # runner_kraken_xrpbtc 'CronJob::KrakenJob.update_price_xrpbtc'
  # runner 'CronJob::KrakenJob.check_order_state'
end

every 2.minute do
  runner_kraken_btcjpy 'CronJob::CoincheckRate.fetch_rate'
end

every 30.minute do
  # runner 'CronJob::KrakenJob.check_order_state'
end

every :day, :at => '4am' do
  # runner "CronJob::PostcardCheck.handle"
end
