require 'lighthouse_stats'

namespace :lighthouse_stats do
  task :load_current do
    Lighthouse.account = ENV['ACCOUNT'] || 'intersect'
    Lighthouse.token   = ENV['TOKEN'] || raise('Supply an account token with TOKEN=')
    @lighthouse = LighthouseStats.new
    @lighthouse.load
    @lighthouse.get_stats
    puts @lighthouse.stats.inspect
  end
  
  task :dump => :load_current do
  end
  
  task :html do

  end
  
end

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

def load_stats_for_date(date)
  filename = filename_for_date(time)
  full_path = File.join(save_path, filename)
  puts "Loading from '#{full_path}' #{File.size(full_path) / 1024}k"
  File.open(full_path, 'r') {|f| stats = Marshal.load(f.read) }
end