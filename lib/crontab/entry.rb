# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require_relative 'parse-error'
require_relative 'period'

module Crontab
  class Entry
    MIN   = Period.new 0, 59
    HOUR  = Period.new 0, 23
    DATE  = Period.new 1, 31
    MONTH = Period.one_based %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
    WDAY  = Period.zero_based %w(Sun Mon Tue Wed Thu Fri Sat Sun)

    @@base_pattern = /^(?<min>\S+)\s+(?<hour>\S+)\s+(?<date>\S+)\s+(?<month>\S+)\s+(?<wday>\S+)\s+(?<command>.+)/
    @@user_pattern = /^(?<min>\S+)\s+(?<hour>\S+)\s+(?<date>\S+)\s+(?<month>\S+)\s+(?<wday>\S+)\s+(?<user>\S+)\s+(?<command>.+)/

    def Entry.from line, lineno, user:false
      pattern = user ? @@user_pattern : @@base_pattern
      matches = line.strip.match pattern
      if matches.nil?
        raise Crontab::ParseError, "error parsing line #{lineno}: not an entry line '#{line}'"
      else
        new(
          MIN.parse(matches[:min]),
          HOUR.parse(matches[:hour]),
          DATE.parse(matches[:date]),
          MONTH.parse(matches[:month]),
          WDAY.parse(matches[:wday]),
          (matches[:user] rescue nil),
          matches[:command]
        )
      end
    rescue Crontab::ParseError => e
      raise Crontab::ParseError, "error parsing line #{lineno}: #{e}", e.backtrace
    end

    def initialize min, hour, date, month, wday, user, command
      @min = min
      @hour = hour
      @date = date
      @month = month
      @wday = wday
      @user = user
      @command = command
    end
    attr_reader :min, :hour, :date, :month, :wday, :user, :command
  end
end

