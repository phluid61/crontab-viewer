# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require File.expand_path('../spec_helper', __FILE__)

require_relative '../lib/crontab/period'

describe "Period" do

  describe "constructor" do
    it "can have a simple range (min<max)" do
      Crontab::Period.new(0, 1).is_a?(Crontab::Period).should == true
    end
    it "can have a single-value range (min=max)" do
      Crontab::Period.new(0, 0).is_a?(Crontab::Period).should == true
    end
    it "accepts an empty map" do
      Crontab::Period.new(0, 1, {}).is_a?(Crontab::Period).should == true
    end
    it "accepts a valid map" do
      Crontab::Period.new(0, 1, {0=>'a',1=>'b'}).is_a?(Crontab::Period).should == true
    end
    it "accepts a valid map with non-unique names" do
      Crontab::Period.new(0, 1, {0=>'a',1=>'b',2=>'a'}).is_a?(Crontab::Period).should == true
    end
    it "raises an ArgumentError if the range is backwards (min>max)" do
      lambda { Crontab::Period.new(1, 0) }.should raise_error(ArgumentError)
    end
    it "raises an ArgumentError if the map doesn't have Integer keys" do
      lambda { Crontab::Period.new(0, 1, {'a'=>0}) }.should raise_error(ArgumentError)
    end
  end

  describe "accessors" do
    it "return the right values" do
      p = Crontab::Period.new(1, 3)
      p.min.should == 1
      p.max.should == 3
      p.range.should == (1..3)
    end
  end

  describe "\#one_based" do
    it "accepts a list of names, as args" do
      p = Crontab::Period.one_based('a', 'b', 'c')
      p.is_a?(Crontab::Period).should == true
      p.range.should == (1..3)
    end
    it "accepts a list of names, as an array" do
      p = Crontab::Period.one_based %w(a b c)
      p.is_a?(Crontab::Period).should == true
      p.range.should == (1..3)
    end
    it "accepts a list of names, with some repeated" do
      p = Crontab::Period.one_based('a', 'b', 'c', 'a')
      p.is_a?(Crontab::Period).should == true
      p.range.should == (1..3)
      p.max.should == 4
    end
    it "compares names case-insensitively" do
      p = Crontab::Period.one_based('a', 'A')
      p.range.should == (1..1)
      p.max.should == 2
    end
  end

  describe "\#zero_based" do
    it "accepts a list of names, as args" do
      p = Crontab::Period.zero_based('a', 'b', 'c')
      p.is_a?(Crontab::Period).should == true
      p.range.should == (0..2)
    end
    it "accepts a list of names, as an array" do
      p = Crontab::Period.zero_based %w(a b c)
      p.is_a?(Crontab::Period).should == true
      p.range.should == (0..2)
    end
    it "accepts a list of names, with some repeated" do
      p = Crontab::Period.zero_based('a', 'b', 'c', 'a')
      p.is_a?(Crontab::Period).should == true
      p.range.should == (0..2)
      p.max.should == 3
    end
    it "compares names case-insensitively" do
      p = Crontab::Period.zero_based('a', 'A')
      p.range.should == (0..0)
      p.max.should == 1
    end
  end

  describe "#value_of" do
    p = Crontab::Period.one_based %w(a b c a)
    it "returns the correct value of unique names" do
      p.value_of('b').should == 2
      p.value_of('c').should == 3
    end
    it "returns the smallest value of repeated names" do
      p.value_of('a').should == 1
    end
    it "matches names case-insensitively" do
      p.value_of('B').should == 2
    end
    it "returns nil for undefined names" do
      p.value_of('x').nil?.should == true
    end
  end

  describe "#name_of" do
    p = Crontab::Period.one_based %w(a b c A)
    it "returns the correct name of values where the names are unique" do
      p.name_of(2).should == 'b'
      p.name_of(3).should == 'c'
    end
    it "returns the correct name of values where the names are repeated" do
      p.name_of(1).should == 'a'
      p.name_of(4).should == 'A'
    end
    it "returns nil for undefined names" do
      p.value_of(99).nil?.should == true
    end
  end

  describe "#parse_value" do
    describe "with unique names" do
      p = Crontab::Period.one_based %w(a b c)

      it "expands '*' to all values" do
        p.parse_value('*').should == [1,2,3]
      end

      describe "with numbers" do
        it "returns a single value in an array" do
          p.parse_value('2').should == [2]
        end
        it "parses full ranges" do
          p.parse_value('1-3').should == [1,2,3]
        end
        it "parses partial ranges" do
          p.parse_value('2-3').should == [2,3]
        end
        it "parses single-value ranges" do
          p.parse_value('2-2').should == [2]
        end
      end

      describe "with names" do
        it "returns a single value in an array" do
          p.parse_value('b').should == [2]
        end
        it "parses full ranges" do
          p.parse_value('a-c').should == [1,2,3]
        end
        it "parses partial ranges" do
          p.parse_value('b-c').should == [2,3]
        end
        it "parses single-value ranges" do
          p.parse_value('b-b').should == [2]
        end
      end

      it "rejects values out of bounds" do
        lambda { p.parse_value('0') }.should raise_error(Crontab::ParseError) # value<min
        lambda { p.parse_value('4') }.should raise_error(Crontab::ParseError) # value>max
      end
      it "rejects negative ranges" do
        lambda { p.parse_value('2-1') }.should raise_error(Crontab::ParseError)
      end
      it "rejects mixed numbers and names in ranges" do
        lambda { p.parse_value('1-c') }.should raise_error(Crontab::ParseError)
      end
      it "rejects ranges out of bounds" do
        lambda { p.parse_value('0-2') }.should raise_error(Crontab::ParseError) # min<min
        lambda { p.parse_value('1-4') }.should raise_error(Crontab::ParseError) # max>max
      end
      it "rejects ranges with invalid names" do
        lambda { p.parse_value('1-c') }.should raise_error(Crontab::ParseError)
      end
    end

    describe "with repeated names" do
      p = Crontab::Period.one_based %w(a b c a)

      it "expands '*' to all values excluding repeats" do
        p.parse_value('*').should == [1,2,3]
      end

      describe "with numbers" do
        it "returns the lowest value for repeated names" do
          p.parse_value('4').should == [1]
        end
        it "deduplicates repeated names in ranges" do
          p.parse_value('1-4').should == [1,2,3,1]
        end
        it "returns the lowest value for repeated names in ranges" do
          p.parse_value('2-4').should == [2,3,1]
          p.parse_value('3-4').should == [3,1]
        end
      end

      describe "with names" do
        it "returns the lowest value for repeated names" do
          p.parse_value('a').should == [1]
        end
        it "interprets repeated names as their lowest value in ranges" do
          lambda { p.parse_value('b-a') }.should raise_error(Crontab::ParseError) # 'b-a' => '2-1' => negative range
        end
      end
    end
  end

  describe "#extract_ranges" do
    p = Crontab::Period.new 0, 1

    it "returns no ranges from an empty list of values" do
      p.extract_ranges([]).should == []
    end

    it "returns a single range for a contiguous list of values" do
      p.extract_ranges([1,2,3]).should == [1..3]
    end

    it "returns multiple ranges for disjoint lists of values" do
      p.extract_ranges([1,2,4,5,6,8,9]).should == [1..2,4..6,8..9]
    end

    it "returns single-element ranges for isolated values" do
      p.extract_ranges([1,3]).should == [1..1,3..3]
    end
  end

  describe "#parse" do
    p = Crontab::Period.one_based %w(a b c d e f g a)

    it "returns an Instance object" do
      p.parse('1').is_a?(Crontab::Period::Instance).should == true
    end

    # TODO: spec this out!
  end

end

