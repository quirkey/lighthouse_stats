#module: lhs

require 'yaml'
require 'lighthouse_stats'

class Lhs < Thor

  desc 'load_current', 'Load current stats and dump to screen'
  def load_current
    load_settings_from_yaml
    @lighthouse = LighthouseStats.new
    @lighthouse.load
    @lighthouse.get_stats
    puts @lighthouse.stats.inspect
  end

  desc 'dump_current', 'Load current stats and marshall to file'
  def dump_current
    load_current
    dump_stats_for_date(@lighthouse, Time.now)
  end

  def load_settings_from_yaml(yaml_path = '~/.lighthouse_stats/lhs.yml')
    yaml_path = File.expand_path(yaml_path)
    settings = YAML.load(yaml_path)
    Lighthouse.account = settings['account']
    Lighthouse.token   = settings['token']
  end

  protected
  def filename_for_date(time)
    "#{Lighthouse.account}_dump_#{time.strftime('%Y-%m-%d')}.dump"
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
    filename = filename_for_date(time)
    full_path = File.join(save_path, filename)
    unless File.readable?(full_path)
      puts "No dump for #{time}"
      return
    end
    puts "Loading from '#{full_path}' #{File.size(full_path) / 1024}k"
    stats = ""
    File.open(full_path, 'r') {|f| stats = Marshal.load(f.read) }
    stats
  end

  def load_past_days(num_days = 7)
    stats = []
    num_days.times do |n|
      time = n.days.ago
      lh = load_stats_for_date(time)
      stats << [time, lh.get_stats] if lh
    end
    puts stats.inspect
    stats
  end
end