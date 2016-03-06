# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require 'test/unit'
$VERBOSE = true

require_relative '../lib/crontab/parse-error'
require_relative '../lib/crontab/entry'
class Test_entry < Test::Unit::TestCase

  def test__Entry__from__no_user
    # valid lines
    [
      '1 1 1 1 1 foo',                         # single-word command
      '1 1 1 1 1 foo bar baz',                 #  multi-word command
      '1 1 1 1 1 foo && bar > /dev/null 2>&1', # ugly command
      "\t1 \t1\t1 1  1 foo\tbar  ",            # horrible whitespace
    ].each do |str|
      assert_nothing_raised do
        Crontab::Entry.from str, 0
      end
    end

    # invalid lines
    [
      '',              # blank line
      '1 1 1 1 1',     # not enough fields
      'a b c d e cmd', # right number but invalid fields
    ].each do |str|
      assert_raise(Crontab::ParseError) do
        Crontab::Entry.from str, 0
      end
    end
  end

  def test__Entry__from__user_false
    # valid lines
    [
      '1 1 1 1 1 foo',                         # single-word command
      '1 1 1 1 1 foo bar baz',                 #  multi-word command
      '1 1 1 1 1 foo && bar > /dev/null 2>&1', # ugly command
      "\t1 \t1\t1 1  1 foo\tbar  ",            # horrible whitespace
    ].each do |str|
      assert_nothing_raised do
        Crontab::Entry.from str, 0, user:false
      end
    end

    # invalid lines
    [
      '',              # blank line
      '1 1 1 1 1',     # not enough fields
      'a b c d e cmd', # right number but invalid fields
    ].each do |str|
      assert_raise(Crontab::ParseError) do
        Crontab::Entry.from str, 0, user:false
      end
    end
  end

  def test__Entry__from__user_true
    # valid lines
    [
      '1 1 1 1 1 bob foo',                         # single-word command
      '1 1 1 1 1 bob foo bar baz',                 # multi-word command
      '1 1 1 1 1 bob foo && bar > /dev/null 2>&1', # ugly command
      "\t1 \t1\t1 1\t1  bob foo\tbar  ",           # horrible whitespace
    ].each do |str|
      assert_nothing_raised do
        Crontab::Entry.from str, 0, user:true
      end
    end

    # invalid lines
    [
      '',                  # blank line
      '1 1 1 1 1',         # not enough fields (would fail)
      '1 1 1 1 1 bob',     # not enough fields (would pass)
      'a b c d e bob cmd', # right number but invalid fields
    ].each do |str|
      assert_raise(Crontab::ParseError) do
        Crontab::Entry.from str, 0, user:true
      end
    end
  end

  # - - - - - - - - - - - - -

  def test__Entry__mins
    (0..59).each do |m|
      assert_nothing_raised { Crontab::Entry.from "#{m} 1 1 1 1 c", 0 }
    end
    assert_raise(Crontab::ParseError) { Crontab::Entry.from '60 1 1 1 1 c', 0 }
  end
  def test__Entry__hours
    (0..23).each do |h|
      assert_nothing_raised { Crontab::Entry.from "1 #{h} 1 1 1 c", 0 }
    end
    assert_raise(Crontab::ParseError) { Crontab::Entry.from '1 24 1 1 1 c', 0 }
  end
  def test__Entry__dates
    (1..31).each do |d|
      assert_nothing_raised { Crontab::Entry.from "1 1 #{d} 1 1 c", 0 }
    end
    assert_raise(Crontab::ParseError) { Crontab::Entry.from '1 1 0 1 1 c', 0 }
    assert_raise(Crontab::ParseError) { Crontab::Entry.from '1 1 32 1 1 c', 0 }
  end
  def test__Entry__months
    (1..12).each do |m|
      assert_nothing_raised { Crontab::Entry.from "1 1 1 #{m} 1 c", 0 }
    end
    %w(jan feb mar apr may jun jul aug sep oct nov dec).each do |m|
      assert_nothing_raised { Crontab::Entry.from "1 1 1 #{m} 1 c", 0 }
    end
    assert_raise(Crontab::ParseError) { Crontab::Entry.from '1 1 1 0 1 c', 0 }
    assert_raise(Crontab::ParseError) { Crontab::Entry.from '1 1 1 13 1 c', 0 }
  end
  def test__Entry__wdays
    (0..7).each do |d|
      assert_nothing_raised { Crontab::Entry.from "1 1 1 1 #{d} c", 0 }
    end
    %w(sun mon tue wed thu fri sat).each do |d|
      assert_nothing_raised { Crontab::Entry.from "1 1 1 1 #{d} c", 0 }
    end
    assert_raise(Crontab::ParseError) { Crontab::Entry.from '1 1 1 1 8 c', 0 }
  end

  # - - - - - - - - - - - - -

  def test__Entry__accessors
    e = Crontab::Entry.from '1 1 1 1 1 u c', 0, user:true
    assert e.min
    assert e.hour
    assert e.date
    assert e.month
    assert e.wday
    assert e.user
    assert e.command

    f = Crontab::Entry.from '1 1 1 1 1 c', 0
    assert f.min
    assert f.hour
    assert f.date
    assert f.month
    assert f.wday
    assert_nil f.user
    assert f.command
  end
end

