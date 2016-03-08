# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require File.expand_path('../spec_helper', __FILE__)

require_relative '../lib/crontab/period'

describe "Crontab::Period::Instance" do

  describe "constructor" do
    it "accepts three parameters" do
      p = Crontab::Period.new(0, 1)
      Crontab::Period::Instance.new(p, '*', [0,1]).is_a?(Crontab::Period::Instance).should == true
    end
  end

  describe "accessors" do
    it "return the right values" do
      p = Crontab::Period.new(0, 1)
      i = Crontab::Period::Instance.new(p, '*', [0,1])

      i.period.should == p
      i.summary.should == '*'
      i.values.should == [0,1]
    end
  end

end

