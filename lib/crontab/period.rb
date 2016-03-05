# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require_relative 'parse-error'

module Crontab
  class Period
    class Instance
      def initialize period, summary, values
        @period = period
        @summary = summary
        @values = values
      end
      attr_reader :period, :summary, :values
      def inspect
        "\#<#{self.class.name}:#{self.__id__.to_s 16} #{summary.inspect} #{values.inspect}>"
      end
    end

    def Period.one_based *names
      names = names.first if names.length == 1 && names.first.is_a?(Array)
      Period.new 1, names.length, Hash[names.each_with_index.map{|n,i|[i+1,n]}]
    end

    def Period.zero_based *names
      names = names.first if names.length == 1 && names.first.is_a?(Array)
      Period.new 0, names.length-1, Hash[names.each_with_index.map{|n,i|[i,n]}]
    end

    def initialize min, max, map=nil
      raise ArgumentError, "min (#{min}) not less than max (#{max})" unless min < max
      @range = min..max
      @min = min
      @max = max
      @iton = {}
      @ntoi = {}
      @dups = Hash.new {|h,k| k }
      if map
        map.each_pair do |i,n|
          raise ArgumentError, "map key should be an Integer; given #{i.inspect}" unless i.is_a? Integer
          norm = n.to_s.downcase
          j = @ntoi[norm]
          if j
            # allow the smaller of the two numbers in @ntoi;
            # make @dups map larger->smaller
            if i > j
              @dups[i] = j
            else
              @ntoi[norm] = i
              @dups[j] = i
            end
          else
            @ntoi[norm] = i
          end
          @iton[i] = "#{n}".freeze
        end
      end
      # allow for duplicate numbers (e.g 0 and 7 in day-of-week)
      if @dups.empty?
        @range = min..max
      else
        @range = min...@dups.keys.min
      end
    end
    attr_reader :min, :max, :range
    def value_of str
      @ntoi[str.to_s.downcase]
    end
    def name_of i
      @iton[i]
    end

    def parse field
      arr = []
      field.split(',').each do |f|
        m = %r[^(.+)/(\d+)$].match(f)
        if m
          value = parse_value m[1]
          mod   = m[2].to_i

          arr += value.select {|v| (v % mod) == 0 }
        else
          arr += parse_value f
        end
      end

      # compact 'arr', and look for simple patterns
      arr = arr.uniq.sort

      if arr.length == @range.size
        # all possible values
        return Instance.new self, '*', arr
      elsif arr.length == 1
        # a single value
        return Instance.new self, arr.first.to_s, arr
      end

      a = arr.first
      z = arr.last
      r = extract_ranges arr
      if r.length == 1
        # a contiguous range
        return Instance.new self, "#{a}-#{z}", arr
      end

      # look for a modulus that covers all of arr
      mod = (@range.max / 2) + 1
      while mod > 1
        if arr.all? {|e| e % mod == 0 }
          # a simple modulus
          mod_a = (@range.min == 0 ? 0 : mod)
          mod_z = mod * (@range.max / mod).to_i
          if a == mod_a && z == mod_z
            return Instance.new self, "*/#{mod}", arr
          else
            return Instance.new self, "#{a}-#{z}/#{mod}", arr
          end
        end
        mod -= 1
      end

      # return the list of ranges (don't get any fancier)
      return Instance.new self, r.map{|r| r.size == 1 ? "#{r.min}" : "#{r.min}-#{r.max}" }.join(','), arr
    end

    def parse_value str
      case str
      when '*'
        @range.to_a
      when /^(\d+)-(\d+)$/
        a = $1.to_i
        b = $2.to_i
        raise Crontab::ParseError, "'#{str}' invalid, #{a} > #{b}" if a > b
        raise Crontab::ParseError, "'#{str}' invalid, #{a} out of range #{@range}" unless @range.cover? @dups[a]
        raise Crontab::ParseError, "'#{str}' invalid, #{b} out of range #{@range}" unless @range.cover? @dups[b]
        (a..b).to_a.map{|e| @dups[e] }
      when /^\d+$/
        a = @dups[str.to_i]
        raise Crontab::ParseError, "'#{str}' invalid, #{a} out of range #{@range}" unless @range.cover? a
        [a]
      when /^([^-]+)-(.+)$/
        a = @iton[$1.downcase]
        b = @iton[$2.downcase]
        raise Crontab::ParseError, "'#{str}' invalid, '#{$1}' unrecognised" unless a
        raise Crontab::ParseError, "'#{str}' invalid, '#{$2}' unrecognised" unless b
        (a..b).to_a
      else
        a = @iton[str.downcase]
        raise Crontab::ParseError, "'#{str}' invalid, '#{str}' unrecognised" unless a
        [a]
      end
    end

    def extract_ranges arr
      ranges = []
      first  = nil
      last   = nil
      arr.each do |e|
        if first.nil?
          first = last = e
        elsif e == (last + 1)
          last = e
        else
          ranges << (first..last)
          first = last = e
        end
      end
      if first
        ranges << (first..last)
      end
      ranges
    end

    def inspect
      "\#<#{self.class.name}:#{self.__id__.to_s 16} [#{@min}-#{@max}]>"
    end
  end
end

