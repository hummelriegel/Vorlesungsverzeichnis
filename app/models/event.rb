class Event < ActiveRecord::Base
  include PgSearch
  has_and_belongs_to_many :vvzs#, uniq: true
  has_and_belongs_to_many :users
  has_many :event_dates, :dependent => :destroy #, :as => :dates
  has_many :activities, class_name: "EventActivity"
  
  include PgSearch
  multisearchable :against => [:name, :nr, :lecturer, :description]

  pg_search_scope :vvz_search,
    :against => :name,
    :using => {
      :tsearch => {:prefix => true},
      :trigram => {:prefix => true}
    }

  # scope :today, lambda { 
  #   joins(:event_dates).where("DATE(start_time) = DATE(?)", Time.now)
  # }

  # scope :not_ended, lambda { 
  #   where('end_time > ?', Time.now)
  # }

  # scope :tomorrow, lambda { 
  #   joins(:event_dates).where("DATE(start_time) = DATE(?)", Time.now + 1.day)
  # }

  def track_activity(action, data={})
    activity = activities.new action: action
    activity[:data] = data
    activity.save
    activity
  end

  def subscribe(user)
    user.events << self
  end

  def unsubscribe(user)
    user.events.delete self
  end

  def subscribed?(user)
    user.events.include? self
  end

  JSON_PREFIX = "*"

  def name=(name)
    write_attribute(:name, name)
    # ensure that original_name is set
    write_attribute(:original_name, name) if original_name.nil?
  end

  def to_preload
    children = children!.map { |n| n.preload_id }
    [preload_id, name, children]
  end 

  def preload_id
    JSON_PREFIX + id.to_s
  end

  def children!
    events
  end

  def dates; event_dates end
    
  def week
    EventDate.week(id)
  end

  def group_by_day
    groups = dates.group_by {|d| d["time"] + Date.parse(d["date"]).wday.to_s + d["room"] }
    groups.values.map(&:first)
  end
  
  def self.to_ical(events)
    RiCal.Calendar do |cal|
      events.each do |event|
        event.dates.each do |date|
          start_time, end_time = date["time"].split("-")
          date_s = date["date"]
          
          cal.event do |e|
            e.summary     = event.name
            #event.description = "First US Manned Spaceflight\n(NASA Code: Mercury 13/Friendship 7)"
            e.dtstart     = Time.parse(start_time + " " + date_s).getutc
            e.dtend       = Time.parse(end_time + " " + date_s).getutc
            e.location    = date["room"]
            e.url         = event.url
          end
        end
      end
    end
  end

  def as_json(user=nil)
    keys = [:name, :nr, :url, :lecturer].map(&:to_s)
    data = self.attributes.slice(*keys)
    data[:type] = simple_type.rstrip
    data[:description] = j_description
    if user
      data[:authenticated] = true
      data[:subscribed] = subscribed?(user)
    end
    data
  end
  
  # only rails should change these attributes
  SAFE_ATTRIBUTES = [:id, :created_at, :updated_at]

  def same_as?(other)
    self.save_attributes == other.save_attributes
  end

  def save_attributes
    ignored_keys = SAFE_ATTRIBUTES.map(&:to_s)
    self.attributes.except(*ignored_keys) 
  end

  def find_or_create
    Event.where(self.save_attributes).first || self.save && self
  end

  def simple_type
    self._type[/^([^(, ]*)/].to_s
  end

  def j_description
    if data = read_attribute(:description)
      hash = JSON.parse data
      text = hash.reduce("") do |s, item|
        s << "<section class=\"desc\">"
        s << "<h4>%s</h4>" % item[0]
        s << item[1]
        s << "</section>"
      end
      text.html_safe
    end
  rescue JSON::ParserError => e
    logger.warn e.message
    read_attribute(:description).html_safe
  end

end
