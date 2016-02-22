
class Array
  def enjoin
    if length == 1
      join ''
    elsif length == 2
      join ', and '
    else
      "#{slice(0, -2).join(', ')}, and #{last}"
    end
  end
end

class Integer
  def _ x
    "#{self} #{x}#{(self == 1) ? '' : 's'}"
  end
  def oclock
    if self.zero?
      '12 am'
    elsif self < 12
      "#{self} am"
    elsif self == 12
      "#{self} pm"
    else
      "#{self - 12} pm"
    end
  end
  def th
    case self % 100
    when 11, 12, 13
      "#{self}th"
    else
      case self % 10
      when 1
        "#{self}st"
      when 2
        "#{self}nd"
      when 3
        "#{self}rd"
      else
        "#{self}th"
      end
    end
  end
  def wday
    %w(Sun Mon Tue Wed Thu Fri Sat Sun)[self]
  end
  def month
    %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[self-1]
  end
end

class String
  def cr() "\x1B[31m#{self}\x1B[0m"; end
  def cg() "\x1B[32m#{self}\x1B[0m"; end
  def cb() "\x1B[34m#{self}\x1B[0m"; end
  def cc() "\x1B[36m#{self}\x1B[0m"; end
  def cm() "\x1B[35m#{self}\x1B[0m"; end
  def cy() "\x1B[33m#{self}\x1B[0m"; end
end

def print_task min, hour, date, month, wday, command
  str = ''
  pfx = ''
  sfx = ''

  if min.include? :ALL
    str << 'every minute'.cb
    sfx = 'of'
  else
    str << min.map do |m|
      if m.is_a? Hash
        v = m[:value]
        o = m[:of]
        if v == :ALL
          sfx = 'of'
          "every #{o._ 'minute'}"
        elsif v.is_a? Range
          sfx = 'past'
          "every #{o._ 'minute'} between #{v.first} and #{v.last}"
        else
          sfx = 'past'
          "?! every #{o._ 'minute'} at #{v}"
        end
      elsif m.is_a? Range
        sfx = 'past'
        "between #{m.first} and #{m.last}"
      else
        sfx = 'past'
        "at #{m}"
      end
    end.enjoin.cb
  end

  str << " #{sfx} "

  if hour.include? :ALL
    str << 'every hour'.cc
  else
    str << hour.map do |h|
      if h.is_a? Hash
        v = h[:value]
        o = h[:of]
        if v == :ALL
          "every #{o._ 'hour'}"
        elsif v.is_a? Range
          "every #{o._ 'hour'} from #{v.first.oclock} to #{v.last.oclock}"
        else
          "?! every #{o._ 'hour'} that is #{v.oclock}"
        end
      elsif h.is_a? Range
        "every hour from #{h.first.oclock} to #{h.last.oclock}"
      else
        h.oclock
      end
    end.enjoin.cc
  end

  if date.include? :ALL
    if wday.include? :ALL
      str << ' of every day'.cm
    end
  else
    str << ' of ' if !date.empty?
    str << date.map do |d|
      if d.is_a? Hash
        pfx = ''
        v = d[:value]
        o = d[:of]
        if v == :ALL
          "the #{o.th}"
        elsif v.is_a? Range
          "each #{o._ 'day'} between the #{v.first.th} and #{v.last.th}"
        else
          "?! each #{o._ 'day'} on the #{v.th}"
        end
      elsif d.is_a? Range
        "each day between the #{d.first.th} and #{d.last.th}"
      else
        "the #{d.th}"
      end
    end.enjoin.cm
  end

  if wday.include? :ALL
  else
    str << ' on ' if !wday.empty?
    str << wday.map do |d|
      if d.is_a? Hash
        pfx = ''
        v = d[:value]
        o = d[:of]
        if v == :ALL
          "#{o._ 'day'}"
        elsif v.is_a? Range
          "every #{o._ 'day'} from #{v.first.wday} to #{v.last.wday}"
        else
          "?! every #{o._ 'day'} on #{v.wday}"
        end
      elsif d.is_a? Range
        "every day from #{d.first.wday} and #{d.last.wday}"
      else
        "every #{d.wday}"
      end
    end.enjoin.cr
  end

  str << ' of '

  if month.include? :ALL
    str << 'every month'.cg
  else
    str << month.map do |m|
      if m.is_a? Hash
        pfx = ''
        v = m[:value]
        o = m[:of]
        if v == :ALL
          "#{o._ 'month'}"
        elsif v.is_a? Range
          "every #{o._ 'month'} from #{v.first.month} to #{v.last.month}"
        else
          "?! every #{o._ 'month'} on #{v.month}"
        end
      elsif m.is_a? Range
        "every month from #{m.first.month} and #{m.last.month}"
      else
        m.month
      end
    end.enjoin.cg
  end

  str << ": \"#{command.cy}\""
  puts str
end

def parse_line line, lineno
  matches = line.match /^(?<min>\S+)\s+(?<hour>\S+)\s+(?<date>\S+)\s+(?<month>\S+)\s+(?<wday>\S+)\s+(?<command>.+)/
  if matches.nil?
    raise "error parsing line #{lineno}: bad line '#{line}'"
  else
    begin
      min = parse_item matches[:min], 0, 59
      hour = parse_item matches[:hour], 0, 23
      date = parse_item matches[:date], 1, 31
      month = parse_item matches[:month], 1, 12, $months
      wday = parse_item matches[:wday], 0, 7, $days
      command = matches[:command]

      [min, hour, date, month, wday, command]
    rescue => e
      raise "error parsing line #{lineno}: #{e}"
    end
  end
end

def parse_item item, min, max, map=nil
  item.split(',').map do |part|
    a, b = part.split '/'
    parsed = parse_part a, min, max, map
    if b
      raise "invalid combination of single time #{a} and stop value #{b}" if parsed != :ALL and !parsed.is_a? Array
      if b.match /^\d+$/
        parsed = {value:parsed, of:b.to_i}
      else
        raise "invalid stop value #{b}"
      end
    end
    parsed
  end
end

def parse_part part, min, max, map=nil
  if part == '*'
    :ALL
  elsif part.match /^\d+$/
    v = part.to_i
    raise "value #{v} out of range #{min}-#{max}" if v < min || v > max
    v
  elsif (m = part.match(/^(\d+)-(\d+)$/))
    a = m[1].to_i
    b = m[2].to_i
    raise "value #{a} out of range #{min}-#{max}" if a < min || a > max
    raise "value #{b} out of range #{min}-#{max}" if b < min || b > max
    a..b
  elsif map && (v = map[part.downcase])
    v
  else
    raise "invalid value #{part}"
  end
end


$months = {}
%w(jan feb mar apr may jun jul aug sep oct nov dec).each_with_index do |n, i|
  $months[n] = i+1
end

$days = {}
%w(sun mon tue wed thu fri sat).each_with_index do |n, i|
  $days[n] = i+1
end

begin
  $env = {}
  $schedule = []

  ARGF.each_line.each_with_index do |line, lineno|
    line.sub! /#.*$/, ''
    line.strip!
    if !line.empty?
      m = line.match /^([A-Z][A-Z0-9_]*)=(.*)$/i
      if m
        $env[m[1]] = m[2]
      else
        $schedule << parse_line(line, lineno)
      end
    end
  end

  if !$env.empty?
    puts "Environment:", "------------"
    $env.each_pair do |k,v|
      puts "  #{k} = #{v}"
    end
  end
  puts "Schedule:", "---------"
  $schedule.each do |task|
    print_task *task
  end
rescue => e
  STDERR.puts e
end
