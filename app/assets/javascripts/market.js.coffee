#= require google_analytics_object
#= require es5-shim.min
#= require es5-sham.min
#= require jquery
#= require jquery_ujs
#= require jquery.mousewheel
#= require jquery-timing.min
#= require jquery.nicescroll.min
#
#= require bootstrap
#= require bootstrap-switch.min
#= require angular
#
#= require moment
#= require bignumber
#= require underscore
#= require cookies.min
#= require flight.min
#= require pusher.min

#= require ./lib/plugin-share-line
#= require ./lib/sfx
#= require ./lib/notifier
#= require ./lib/pusher_connection

#= require highstock
#= require_tree ./highcharts/

#= require_tree ./helpers
#= require_tree ./component_mixin
#= require_tree ./component_data
#= require_tree ./component_ui
#= require_tree ./templates

#= require social-share-button
#= require_self

#= require charting_library/charting_library.min
#= require charting_library/datafeed

$ ->
  window.notifier = new Notifier()

  BigNumber.config(ERRORS: false)

  HeaderUI.attachTo('nav')
  AccountSummaryUI.attachTo('#account_summary')

  FloatUI.attachTo('.float')
  # KeyBindUI.attachTo(document)
  # AutoWindowUI.attachTo(window)


  OrderBookUI.attachTo('#order_book')
  PlaceOrderUI.attachTo('#bid_entry')
  PlaceOrderUI.attachTo('#ask_entry')
  # DepthUI.attachTo('#depths_wrapper')

  MyOrdersUI.attachTo('#my_orders')
  # MarketTickerUI.attachTo('#ticker')
  # MarketSwitchUI.attachTo('#market_list_wrapper')
  MarketTradesUI.attachTo('#market_trades_wrapper')

  MarketData.attachTo(document)
  GlobalData.attachTo(document, {pusher: window.pusher})
  MemberData.attachTo(document, {pusher: window.pusher}) if gon.accounts

  ChartsUI.attachTo('#charts')
  CandlestickUI.attachTo('#charts')
  LineChartUI.attachTo('#charts')
  RangeSwitchUI.attachTo('#range_switch_select')

  $('.panel-body-content').niceScroll
    autohidemode: true
    cursorborder: "none"
