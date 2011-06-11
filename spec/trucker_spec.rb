require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Trucker builds ActiveRecord queries in Rails 3 syntax" do
  before(:each) do
    ENV['offset'] = nil
    ENV['limit'] = nil
    ENV['where'] = nil
    @model = Trucker::Model.new("muppets")
  end
  it "handles limits" do
    ENV['limit'] = "20"
    @model.limit.should == ".limit(20)"
    @model.construct_query.should == "LegacyMuppet.limit(20)"
  end
  it "handles ordering" do
    ENV['offset'] = "20"
    @model.offset.should == ".offset(20)"
    @model.construct_query.should == "LegacyMuppet.offset(20)"
  end
  it "handles an unmodified .all()" do
    @model.construct_query.should == "LegacyMuppet.all"
  end
  it "handles where()" do
    ENV['where'] = ":username => 'fred'"
    @model.construct_query.should == "LegacyMuppet.where(:username => 'fred')"
  end
end

describe "Trucker can handle fucking underscores" do
  Trucker::Model.new("muppets").base.should == "LegacyMuppet"
  Trucker::Model.new("muppet_balls").base.should == "LegacyMuppetBall"
end

