require 'spec_helper'

describe Market do

  context 'visible market' do
    # it { expect(Market.orig_all.count).to eq(2) }
    it { expect(Market.all.count).to eq(1) }
  end

  context 'markets hash' do
    it "should list all markets info" do
      Market.to_hash.should == {:btcjpy=>{:name=>"BTC/JPY", :base_unit=>"btc", :quote_unit=>"jpy"}}
    end
  end

  context 'market attributes' do
    subject { Market.find('btcjpy') }

    its(:id)         { should == 'btcjpy' }
    its(:name)       { should == 'BTC/JPY' }
    its(:base_unit)  { should == 'btc' }
    its(:quote_unit) { should == 'jpy' }
    its(:visible)    { should be_true }
  end

  context 'enumerize' do
    subject { Market.enumerize }

    it { should be_has_key :btcjpy }
    it { should be_has_key :ptsbtc }
  end

  context 'shortcut of global access' do
    subject { Market.find('btcjpy') }

    its(:bids)   { should_not be_nil }
    its(:asks)   { should_not be_nil }
    its(:trades) { should_not be_nil }
    its(:ticker) { should_not be_nil }
  end

end
