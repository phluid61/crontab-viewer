# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require 'test/unit'
$VERBOSE = true

require_relative '../lib/crontab/parse-error'
require_relative '../lib/crontab/period'
class Test_period < Test::Unit::TestCase

  def test__Period__constructor
    assert_nothing_raised { Crontab::Period.new 0, 1 }                  # simple range
    assert_nothing_raised { Crontab::Period.new 0, 0 }                  # single value
    assert_nothing_raised { Crontab::Period.new 0, 1, {} }              # empty map
    assert_nothing_raised { Crontab::Period.new 0, 1, {0=>'a',1=>'b'} } # map

    assert_raise(ArgumentError) { Crontab::Period.new 1, 0 }            # reverse range
    assert_raise(ArgumentError) { Crontab::Period.new 0, 1, {'a'=>0} }  # bad map
  end

  def test__Period__accessors
    p = Crontab::Period.new 0, 1
    assert_equal 0, p.min
    assert_equal 1, p.max
    assert_equal 0..1, p.range
  end

  def test__Period__one_based
    p = Crontab::Period.one_based %w(a b c)
    assert_equal 1, p.min
    assert_equal 3, p.max

    q = Crontab::Period.one_based *%w(a b c)
    assert_equal 1, q.min
    assert_equal 3, q.max
  end

  def test__Period__zero_based
    p = Crontab::Period.zero_based %w(a b c)
    assert_equal 0, p.min
    assert_equal 2, p.max

    q = Crontab::Period.zero_based *%w(a b c)
    assert_equal 0, q.min
    assert_equal 2, q.max
  end

  def test__Period__value_of
    p = Crontab::Period.zero_based %w(a b c)
    assert_equal 0, p.value_of('a')
    assert_equal 1, p.value_of('b')
    assert_equal 2, p.value_of('c')
    assert_nil p.value_of('x')
  end

  def test__Period__name_of
    p = Crontab::Period.zero_based %w(a b c)
    assert_equal 'a', p.name_of(0)
    assert_equal 'b', p.name_of(1)
    assert_equal 'c', p.name_of(2)
    assert_nil p.name_of(99)
  end

  def test__Period__parse_value
    p = Crontab::Period.one_based %w(a b c)

    assert_equal [1,2,3], p.parse_value('*')

    assert_equal [1,2,3], p.parse_value('1-3')
    assert_equal [1,2],   p.parse_value('1-2')
    assert_equal [2],     p.parse_value('2')

    assert_equal [1,2,3], p.parse_value('a-c')
    assert_equal [1,2],   p.parse_value('a-b')
    assert_equal [2],     p.parse_value('b')

    # todo: negative range
    # todo: range below min
    # todo: range above max
    # todo: value below min
    # todo: value above max
    # todo: bad word
  end

  def test__Period__extract_ranges
    p = Crontab::Period.new 0, 1

    [
      [[],              []],
      [[1..3],          [1,2,3]],
      [[1..2,4..6,8..9],[1,2,4,5,6,8,9]],
      [[1..1,3..3],     [1,3]],
    ].each do |x,a|
      assert_equal x, p.extract_ranges(a)
    end
  end

  def test__Period__parse
    p = Crontab::Period.one_based %w(a b c d e f g a)

    # returns an Instance
    assert_equal Crontab::Period::Instance, p.parse('1').class

    # todo ...
  end

end

