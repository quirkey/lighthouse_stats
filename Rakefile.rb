require 'lighthouse_stats'

namespace :lighthouse_stats do
  task :load_current do
    Lighthouse.account = ENV['ACCOUNT'] || 'intersect'
    Lighthouse.token   = ENV['TOKEN'] || raise('Supply an account token with TOKEN=')
    @lighthouse = LighthouseStats.new
    @lighthouse.load
  end
  
  task :dump => :load_current do
    path = ENV['TO_PATH'] || File.expand_path('~/.lighthouse_stats/')
    FileUtils.mkdir_p(path)
    filename = "#{Lighthouse.account}_dump_#{Time.now.strftime('%Y-%m-%d')}.dump"
    full_path = File.join(path, filename)
    puts "Marshaling to '#{full_path}'"
    File.open(full_path, 'w') {|f| f << Marshal.dump(@lighthouse) }
    puts "Wrote #{File.size(full_path) / 1024}k"
  end
  
end