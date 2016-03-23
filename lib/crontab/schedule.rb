# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require_relative 'entry'
require_relative 'env'

module Crontab
  class Schedule

    # @param [File|IO] input -- something that responds to #each_line
    def initialize input=nil
      @env = Crontab::Env.new
      @entries = []

      interpret input if input
    end
    attr_reader :env

    # @param [File|IO] input -- something that responds to #each_line
    def interpret input
      input.each_line.each_with_index do |line, lineno|
        line.sub! /#.*$/, ''
        line.strip!
        if !line.empty?
          if @env.recognise? line
            @env.parse(line, lineno)
          else
            @entries << Crontab::Entry.from(line, lineno)
          end
        end
      end
      # TODO: rationalise the entries
    end

    def each_entry &b
      @entries.each &b
    end

    # experimental APIs:

    def entries_at_time h, m
      @entries.select{|e| e.hour.include?(h) && e.min.include?(m)}
    end

    def entries_on_date d, m
      @entries.select{|e| e.date.include?(d) && e.month.include?(m)}
    end

    def entries_by_wday
      map = Hash.new {|h,k| h[k] = [] }
      @entries.each do |e|
        e.wday.each do |d|
          map[d] << e
        end
      end
      map
    end
    def entries_by_time
      map = Hash.new {|h,k| h[k] = [] }
      @entries.each do |e|
        e.hour.values.product(e.min.values) do |hm|
          time = '%02d:%02d' % hm
          map[time] << e
        end
      end
      map
    end
    def entries_by_date
      map = Hash.new {|h,k| h[k] = [] }
      @entries.each do |e|
        e.month.values.product(e.date.values) do |md|
          date = '%02d-%02d' % md
          map[date] << e
        end
      end
      map
    end

    def stupid_entries
      @entries.select {|e| e.stupid? }
    end
    def hourly_entries
      @entries.select {|e| e.hourly? }
    end
    def daily_entries
      @entries.select {|e| e.daily? }
    end
    def weekly_entries
      @entries.select {|e| e.weekly? }
    end
    def monthly_entries
      @entries.select {|e| e.monthly? }
    end
    def yearly_entries
      @entries.select {|e| e.yearly? }
    end
    def nonstandard_entries
      @entries.reject do |e|
        e.stupid? || e.hourly? || e.daily? || e.weekly? || e.monthly? || e.yearly?
      end
    end

  end
end

