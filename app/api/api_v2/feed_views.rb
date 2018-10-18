module APIv2
  class FeedViews < Grape::API
    helpers ::APIv2::NamedParams

    desc 'Get ticker of all markets.'

  end
end
