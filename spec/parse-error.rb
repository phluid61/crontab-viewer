# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require File.expand_path('../spec_helper', __FILE__)

require_relative '../lib/crontab/parse-error'

describe "Crontab::ParseError" do

  it "is a StandardError" do
    Crontab::ParseError.ancestors.include?(StandardError).should == true
  end

end

