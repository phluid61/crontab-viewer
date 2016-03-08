# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require File.expand_path('../spec_helper', __FILE__)

require_relative '../lib/crontab/env'

describe "Crontab::Env" do

  describe "\#recognise?" do
    e = Crontab::Env.new

    it "returns truthy for matching lines" do
      [
        'FOO=bar',
        'foo=bar',
        'baz = qux',
        ' Fre=bble',
        'Bit=',
      ].each do |line|
        result = e.recognise?(line)
        (!!result).should == true
      end
    end

    it "returns falsy for non-matching lines" do
      [
        '',
        'foo',
        'foo bar=baz',
        '123=baz',
        '0 12 * * * a b',
      ].each do |line|
        result = e.recognise?(line)
        (!!result).should == false
      end
    end
  end

  describe "\#parse" do
    e = Crontab::Env.new

    it "parses valid lines into Instances" do
      [
        'FOO=bar',
        'baz = qux',
        ' Fre=bble',
        'Bit=',
      ].each_with_index do |line, i|
        e.parse(line, i).is_a?(Crontab::Env::Instance).should == true
      end
    end

    it "rejects invalid lines with ParseError" do
      [
        '',
        'foo',
        'foo bar=baz',
        '123=baz',
        '0 12 * * * a b',
      ].each_with_index do |line, i|
        lambda { e.parse(line, i) }.should raise_error(Crontab::ParseError)
      end
    end
  end

  describe "\#[]" do
    e = Crontab::Env.new
    e.parse 'FOO=bar', 0

    it "returns an Instance for a set var" do
      i = e['FOO']

      i.is_a?(Crontab::Env::Instance).should == true
      i.name.should == 'FOO'
      i.value.should == 'bar'
    end

    it "returns nil for unset var" do
      e['QUX'].nil?.should == true
    end
  end

  describe "\#length" do
    it "returns the right length" do
      e = Crontab::Env.new
      [
        'FOO=bar',
        'foo=bar',
        'baz=qux',
        'Fre=bble',
      ].each_with_index do |line, i|
        e.length.should == i
        e.parse line, 0
      end
    end
  end

  describe "\#keys" do
    it "returns the correct names" do
      e = Crontab::Env.new
      e.parse 'FOO=bar', 0
      e.parse 'foo=bar', 1
      e.parse 'baz=qux', 2
      e.parse 'Fre=bble', 3
      e.keys.should == %w(FOO foo baz Fre)
    end
  end

  # TODO
  #describe "\#each_pair" do
  #  it "iterates over the pairs" do
  #  end
  #end

end

