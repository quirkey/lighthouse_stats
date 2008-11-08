require 'rubygems'
require 'lighthouse-api'
require 'gchart'

module Lighthouse 
  class Ticket < Base
    attr_accessor :project
    
  end

  class Project < Base
    def to_s
      "#{name}"
    end
  end
end

class LighthouseStats
  attr_accessor :projects, :tickets

  def initialize
    
  end

  def load
    puts "Fetching Projects"
    @projects = Lighthouse::Project.find(:all)
    puts "Fetching Tickets"
    @tickets = @projects.collect do |p| 
      puts "Fetching Tickets for '#{p}'"
      tickets = []
      page = 1
      begin
        page_of_tickets = p.tickets(:q => 'responsible:any', :page => page)
        puts "Getting Page #{page} : #{page_of_tickets.length} Tickets"
        tickets.concat page_of_tickets
        page += 1
      end while page_of_tickets.length == 30
      puts "#{tickets.length} tickets"
      tickets.each {|t| t.project = p }
      tickets
    end.flatten
    puts "Total : #{@tickets.length} Tickets"
  end
  
end

Lighthouse.account = ENV['ACCOUNT']
Lighthouse.token   = ENV['TOKEN']

stats = LighthouseStats.new
stats.load
stats.tickets