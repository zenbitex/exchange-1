require 'spec_helper'

describe BuyCoinController do

  describe "GET 'show'" do
    it "returns http success" do
      get 'show'
      response.should be_success
    end
  end

  describe "GET 'buy'" do
    it "returns http success" do
      get 'buy'
      response.should be_success
    end
  end

end
