# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require File.expand_path('../spec_helper', __FILE__)

require_relative '../lib/crontab/period'
require_relative '../lib/crontab/entry'

describe "Crontab::Entry" do

  describe "constants" do
    it "are Periods" do
      Crontab::Entry::MIN.is_a?(Crontab::Period).should == true
      Crontab::Entry::HOUR.is_a?(Crontab::Period).should == true
      Crontab::Entry::DATE.is_a?(Crontab::Period).should == true
      Crontab::Entry::MONTH.is_a?(Crontab::Period).should == true
      Crontab::Entry::WDAY.is_a?(Crontab::Period).should == true
    end
  end

  min   = Crontab::Period::Instance.new Crontab::Entry::MIN, '0', [0]
  hour  = Crontab::Period::Instance.new Crontab::Entry::HOUR, '12', [12]
  date  = Crontab::Period::Instance.new Crontab::Entry::DATE, '*', Crontab::Entry::DATE.range.to_a
  month = Crontab::Period::Instance.new Crontab::Entry::MONTH, '*', Crontab::Entry::MONTH.range.to_a
  wday  = Crontab::Period::Instance.new Crontab::Entry::WDAY, '1', [1]
  user  = 'user'
  command1 = 'cmd'
  command2 = 'cmd -o foo'

  anon_line1 = "#{min.summary} #{hour.summary} #{date.summary} #{month.summary} #{wday.summary} #{command1}"
  anon_line2 = "#{min.summary} #{hour.summary} #{date.summary} #{month.summary} #{wday.summary} #{command2}"
  user_line1 = "#{min.summary} #{hour.summary} #{date.summary} #{month.summary} #{wday.summary} #{user} #{command1}"
  user_line2 = "#{min.summary} #{hour.summary} #{date.summary} #{month.summary} #{wday.summary} #{user} #{command2}"

  describe "constructor" do
    it "accepts seven parameters including user" do
      Crontab::Entry.new(min, hour, date, month, wday, user, command1).is_a?(Crontab::Entry).should == true
    end

    it "accepts seven parameters where the user is nil" do
      Crontab::Entry.new(min, hour, date, month, wday, nil, command1).is_a?(Crontab::Entry).should == true
    end
  end

  describe "accessors" do
    it "return the right values" do
      e = Crontab::Entry.new(min, hour, date, month, wday, user, command1)
      e.is_a?(Crontab::Entry).should == true
      e.min.should == min
      e.hour.should == hour
      e.date.should == date
      e.month.should == month
      e.wday.should == wday
      e.user.should == user
      e.command.should == command1

      f = Crontab::Entry.new(min, hour, date, month, wday, nil, command1)
      f.is_a?(Crontab::Entry).should == true
      f.min.should == min
      f.hour.should == hour
      f.date.should == date
      f.month.should == month
      f.wday.should == wday
      f.user.nil?.should == true
      f.command.should == command1
    end
  end

  describe "#from" do
    describe "with 2 args" do
      it "parses a 6-field line into an Entry" do
        e = Crontab::Entry.from anon_line1, 0
        e.is_a?(Crontab::Entry).should == true
        e.user.nil?.should == true
        e.command.should == command1
      end
      it "accepts a multi-word command" do
        e = Crontab::Entry.from anon_line2, 0
        e.is_a?(Crontab::Entry).should == true
        e.user.nil?.should == true
        e.command.should == command2
      end
    end
    describe "with user:false" do
      it "parses a 6-field line" do
        e = Crontab::Entry.from anon_line1, 0, user: false
        e.is_a?(Crontab::Entry).should == true
        e.user.nil?.should == true
        e.command.should == command1
      end
      it "accepts a multi-word command" do
        e = Crontab::Entry.from anon_line2, 0, user:false
        e.is_a?(Crontab::Entry).should == true
        e.user.nil?.should == true
        e.command.should == command2
      end
    end
    describe "with user:true" do
      it "requires at least 7 fields" do
        lambda { Crontab::Entry.from anon_line1, 0, user: true }.should raise_error(Crontab::ParseError)
      end
      it "parses a 7-field line" do
        e = Crontab::Entry.from user_line1, 0, user: true
        e.is_a?(Crontab::Entry).should == true
        e.user.should == user
        e.command.should == command1
      end
      it "accepts a multi-word command" do
        e = Crontab::Entry.from user_line2, 0, user:true
        e.is_a?(Crontab::Entry).should == true
        e.user.should == user
        e.command.should == command2
      end
    end
  end

end

