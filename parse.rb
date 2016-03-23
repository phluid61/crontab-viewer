# encoding: UTF-8
# vim: ts=2 sts=2 sw=2 expandtab

require_relative 'lib/crontab/schedule'
include Crontab

begin
  if ARGV.empty?
    sched = File.open('test.crontab') {|f| Schedule.new f }
  else
    sched = Schedule.new ARGF
  end
rescue Crontab::ParseError => e
  STDERR.puts e
  exit 1
end

puts "Environment:"
sched.env.each_pair do |k,v|
  puts "  #{k} = #{v.inspect}"
end
puts ''

puts "Every minute:"
sched.stupid_entries.each do |e|
  puts "  #{e.user}\t#{e.command}"
end
puts ''

puts "Every hour:"
sched.hourly_entries.sort{|a,b| a.min.first<=>b.min.first }.each do |e|
  t = 'mm-dd hh:%02d' % e.min.first
  puts "  #{t}\t#{e.user}\t#{e.command}"
end
puts ''

puts "Every day:"
sched.daily_entries.sort{|a,b| (a.hour.first<=>b.hour.first).nonzero? || a.min.first<=>b.min.first }.each do |e|
  t = 'mm-dd %02d:%02d' % [e.hour.first, e.min.first]
  puts "  #{t}\t#{e.user}\t#{e.command}"
end
puts ''

puts "Every week:"
sched.weekly_entries.sort{|a,b| (a.wday.first<=>b.wday.first).nonzero? || (a.hour.first<=>b.hour.first).nonzero? || a.min.first<=>b.min.first }.each do |e|
  d = %w(Sun Mon Tue Wed Thu Fri Sat Sun)[e.wday.first]
  t = '%02d:%02d' % [e.hour.first, e.min.first]
  puts "  #{d} #{t}\t#{e.user}\t#{e.command}"
end
puts ''

puts "Every month:"
sched.monthly_entries.sort{|a,b| (a.date.first<=>b.date.first).nonzero? || (a.hour.first<=>b.hour.first).nonzero? || a.min.first<=>b.min.first }.each do |e|
  t = 'mm-%02d %02d:%02d' % [e.date.first, e.hour.first, e.min.first]
  puts "  #{t}\t#{e.user}\t#{e.command}"
end
puts ''

puts "Every year:"
sched.yearly_entries.sort{|a,b| (a.month.first<=>b.date.first).nonzero? || (a.date.first<=>b.date.first).nonzero? || (a.hour.first<=>b.hour.first).nonzero? || a.min.first<=>b.min.first }.each do |e|
  t = '%02d-%02d %02d:%02d' % [e.month.first, e.date.first, e.hour.first, e.min.first]
  puts "  #{t}\t#{e.user}\t#{e.command}"
end
puts ''

puts "Others:"
sched.nonstandard_entries.each do |e|
  puts "  #{e.summary}"
end
puts ''

