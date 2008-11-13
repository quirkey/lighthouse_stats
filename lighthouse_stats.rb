require 'rubygems'
require 'lighthouse-api'
require 'active_support'
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
  
  class User < Base
    def to_s
      "#{name}"
    end
  end
end

class LighthouseStats
  attr_accessor :projects, :tickets, :users, :stats

  def initialize
    @projects = []
    @tickets  = []
    @users    = {}
    @stats    = {}
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
    the_tickets = options[:find] ? @tickets.find_all(&options.delete(:find)) : @tickets
    the_tickets = options[:sort] ? the_tickets.sort(options.delete(:sort)) : the_tickets
    grouped_by = the_tickets.group_by(&block)
    options[:label_key] ||= :labels
    data   =  grouped_by.values.collect {|t| t.length }
    labels =  grouped_by.keys
    puts data.inspect
    puts labels.inspect
    Gchart.send(chart_type, {:data => data, options[:label_key] => labels}.merge(options))
  end

  def get_stats
    @stats[:total_tickets] = @tickets.length
    @stats[:open_tickets_by_type] = ticket_counts_from_hash(open_tickets_by_type)
    @stats[:open_tickets_by_user] = ticket_counts_from_hash(open_tickets_by_user)
    @stats[:open_tickets_by_type_by_user] = open_tickets_by_type_by_user
    @stats[:open_tickets_by_project] = ticket_counts_from_hash(open_tickets_by_project)
    @stats[:resolved_tickets_by_project] = ticket_counts_from_hash(resolved_tickets_by_project)
    @stats[:open_tickets_by_type_by_project] = open_tickets_by_type_by_project
    @stats[:tickets_touched] = tickets_touched.length
    @stats[:tickets_created] = tickets_created.length
    @stats
  end

  def open_tickets
    @tickets.find_all {|t| t.closed == false}
  end

  def resolved_tickets
    @tickets.find_all {|t| t.closed == true}
  end

  def open_tickets_by_type
    open_tickets.group_by {|t| t.state }
  end
  
  def open_tickets_by_user
    open_tickets.group_by {|t| t.assigned_user.to_s }
  end
  
  def open_tickets_by_type_by_user
    open_tickets_by_user.collect do |user_name, tickets|
      [user_name, ticket_counts_from_hash(tickets.group_by {|t| t.state })]
    end
  end
  
  def open_tickets_by_project
    open_tickets.group_by {|t| t.project.to_s }
  end
  
  def resolved_tickets_by_project
    resolved_tickets.group_by {|t| t.project.to_s }
  end
  
  def open_tickets_by_type_by_project
    open_tickets_by_project.collect do |project_name, tickets|
      [project_name, ticket_counts_from_hash(tickets.group_by {|t| t.state })]
    end
  end
  
  def ticket_counts_from_hash(hash)
    hash.collect {|a,tickets| [a, tickets.length] }
  end
  
  def tickets_touched
    @tickets.find_all {|t| t.updated_at.to_date == Time.now.to_date }
  end
  
  def tickets_created
    @tickets.find_all {|t| t.created_at.to_date == Time.now.to_date }
  end
  
end

Lighthouse.account = ENV['ACCOUNT']
Lighthouse.token   = ENV['TOKEN']

# lighthouse.tickets_grouped_by_chart(:pie, :find => lambda {|t| t.closed == false }, :width => 500, :height => 250) {|t| t.state }
