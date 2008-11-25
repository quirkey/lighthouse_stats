#module: lhs

require 'yaml'
require 'pp'
require 'erb'
require 'lighthouse_stats'

class Lhs < Thor

  desc 'load_current', 'Load current stats and dump to screen'
  def load_current
    load_settings_from_yaml
    @lighthouse = LighthouseStats.new
    @lighthouse.load
    @lighthouse.get_stats
    pp @lighthouse.stats
  end

  desc 'dump_current', 'Load current stats and marshall to file'
  def dump_current
    load_current
    dump_stats_for_date(@lighthouse, Time.now)
  end

  desc 'to_html [NUM_DAYS:7]', 'Loads the past NUM_DAYS days and exports to a html file'
  def to_html(num_days = 7)
    load_settings_from_yaml
    # dump_current unless dump_exists?(Time.now)
    @stats = load_past_days(num_days)
    html = ERB.new(File.read('stats.html.erb')).result(binding)
    html_path = File.join(save_path, filename_for_date(Time.now,'html'))
    File.open(html_path, 'w') {|f| f << html }
    `open #{html_path}`
  end
  
  desc 'to_html [NUM_DAYS:7]', 'Loads the past NUM_DAYS days and dumps them to screen'
  def print_past_days(num_days = 7)
    load_settings_from_yaml
    @stats = load_past_days(num_days)
    puts @stats.inspect
  end
  
  protected
  def load_settings_from_yaml(yaml_path = '~/.lighthouse_stats/lhs.yml')
    yaml_path = File.expand_path(yaml_path)
    raise "Please set up #{yaml_path} with your lighthouse info" unless File.readable?(yaml_path)
    settings = YAML.load_file(yaml_path)
    Lighthouse.account = settings['account']
    Lighthouse.token   = settings['token']
  end
  
  def filename_for_date(time, type = 'dump')
    "#{Lighthouse.account}_#{type}_#{time.strftime('%Y-%m-%d')}.#{type}"
  end

  def save_path
    path = ENV['TO_PATH'] || File.expand_path('~/.lighthouse_stats/')
    FileUtils.mkdir_p(path)
  end

  def dump_stats_for_date(stats, time)
    filename = filename_for_date(time)
    full_path = File.join(save_path, filename)
    puts "Marshaling to '#{full_path}'"
    File.open(full_path, 'w') {|f| f << Marshal.dump(stats) }
    puts "Wrote #{File.size(full_path) / 1024}k"
  end

  def load_stats_for_date(time)
    unless full_path = dump_exists?(time)
      puts "No dump for #{time}"
      return
    end
    puts "Loading from '#{full_path}' #{File.size(full_path) / 1024}k"
    stats = ""
    File.open(full_path, 'r') {|f| stats = Marshal.load(f.read) }
    stats
  end
  
  def dump_exists?(time)
    filename = filename_for_date(time)
    full_path = File.join(save_path, filename)
    File.readable?(full_path) ? full_path : false
  end

  def load_past_days(num_days = 7)
    stats = []
    (0..num_days.to_i).each do |n|
      time = n.days.ago
      lh = load_stats_for_date(time)
      stats << [time, lh.get_stats] if lh
    end
    pp stats
    stats
  end
  
  def stats_over_time(stat_name)
    collected_stats = {}
    times           = []
    @stats.each do |time, date_stats|
      times << time
      date_stats[stat_name].each do |key, num|
        collected_stats[key] ||= []
        collected_stats[key] << num
      end
    end
    {:collected => collected_stats, :times => times}
  end
end