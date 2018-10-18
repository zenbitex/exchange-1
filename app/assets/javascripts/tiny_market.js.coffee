$ ->
  MarketData.attachTo(document)
  GlobalData.attachTo(document, {pusher: window.pusher})
  MemberData.attachTo(document, {pusher: window.pusher}) if gon.accounts

  ChartsUI.attachTo('#charts')
  CandlestickUI.attachTo('#charts')
  LineChartUI.attachTo('#charts')
  RangeSwitchUI.attachTo('#range_switch_select')
