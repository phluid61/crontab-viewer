# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require_relative 'entry'
require_relative 'env'

module Crontab
  class Schedule

    def initialize
      @env = Crontab::Env.new
      @entries = []
    end

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

  end
end

