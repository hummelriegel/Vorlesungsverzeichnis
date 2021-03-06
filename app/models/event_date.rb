class EventDate < ActiveRecord::Base
  belongs_to :event
  self.inheritance_column = nil
  
  validates :start_time, presence: true


  #EventDate.where(event_id: events)

  # scope :upcomming, lambda { 
  #   not_ended.where("DATE(start_time) = DATE(?) OR DATE(start_time) = DATE(?)", Time.now, Time.now + 1.day)
  # }

  scope :today, lambda { day(Time.now) }

  scope :not_ended, lambda { 
    where('end_time > ?', Time.now)
  }

  scope :tomorrow, lambda { day(Time.now + 1.day) }

  scope :day, lambda { |day|
    where("DATE(start_time) = DATE(?)", day)
  }

  scope :after_now, lambda {
    where('end_time < ?', Time.now).order(:end_time)
  }

  scope :by_user, lambda { |user|
    joins(:event => :users).where("users.id" => User.first)
  }

  # Returns the day of the date as an Integer
  # monday = 0, tuesday = 1, ..., sunday = 6
  def day
    index = start_time.wday # sunday = 0, monday = 1, ...
    index == 0 ? 6 : index - 1
  end

  def today?
    start_time.today?
  end

  def title
    t = ""
    t += event.name
    t += " (Klausur)" if type == "exam"
    t
  end

  def start_time
    correct_time read_attribute(:start_time)
  end

  def end_time
    correct_time read_attribute(:end_time)
  end

  private

  def correct_time(time)
    time.in_time_zone("CET") - 1.hour
  end

end
