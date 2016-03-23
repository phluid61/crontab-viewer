# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require_relative 'entry'

module Crontab
  class Env
    class Instance
      def initialize name, value
        @name = name
        @value = value
      end
      attr_reader :name, :value
      def inspect
        "\#<#{self.class.name}:#{self.__id__.to_s 16} #{@name}=\"#{@value}\">"
      end
    end

    @@pattern = /^([A-Z_][A-Z0-9_]*)\s*=\s*(.*)$/i

    def initialize
      @map = {}
    end

    def each &b
      @map.each_pair do |k,v|
        yield v
      end
    end
    include Enumerable

    def [] name
      @map[name.to_s].value
    end

    def length
      @map.length
    end
    alias :size :length

    def keys
      @map.keys
    end

    def each_pair &b
      @map.each_pair do |k,v|
        yield v.name, v.value
      end
    end

    # returns truthy if the line looks like an ENV setting
    def recognise? line
      line.strip =~ @@pattern
    end
    alias :recognize? :recognise?

    def parse line, lineno
      matches = line.strip.match @@pattern
      if matches.nil?
        raise Crontab::ParseError, "error parsing line #{lineno}: not an env line '#{line}'"
      else
        name = matches[1].freeze
        value = matches[2].freeze
        @map[name] = Instance.new(name, value)
      end
    end
  end
end

