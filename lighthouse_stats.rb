require 'rubygems'
require 'lighthouse-api'
require 'gchart'

module Lighthouse 
  class Ticket < Base
    attr_accessor :project, :user, :assigned_user
  end

  class Project < Base
    def to_s
      "#{name}"
    end
  end
end

class LighthouseStats
  attr_accessor :projects, :tickets, :users

  def initialize
    @projects = []
    @tickets  = []
    @users    = {}
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
      tickets.each {|t|
        t.user    = user(t.user_id)
        t.assigned_user = user(t.assigned_user_id)
        t.project = p 
      }
      tickets
    end.flatten
    puts "Total : #{@tickets.length} Tickets"
  end
  
  def user(user_id)
    @users[user_id.to_i] ||= Lighthouse::User.find(user_id)    
  end
  
  def tickets_grouped_by_chart(chart_type, options = {}, &block)
    the_tickets = options[:find] ? @tickets.find_all(options.delete(:find)) : @tickets
    the_tickets = options[:sort] ? the_tickets.sort(options.delete(:sort)) : the_tickets
    grouped_by = the_tickets.group_by(&block)
    options[:label_key] ||= :labels
    data   =  grouped_by.values.collect {|t| t.length }
    labels =  grouped_by.keys
    puts data.inspect
    puts labels.inspect
    Gchart.send(chart_type, {:data => data, options[:label_key] => labels}.merge(options))
  end
  
end

Lighthouse.account = ENV['ACCOUNT']
Lighthouse.token   = ENV['TOKEN']