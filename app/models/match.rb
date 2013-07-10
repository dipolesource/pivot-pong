class Match < ActiveRecord::Base
  validates :winner,      presence: true
  validates :loser,       presence: true

  belongs_to :winner, class_name: Opponent.name, autosave: true
  belongs_to :loser, class_name: Opponent.name, autosave: true

  before_validation :set_default_occured_at_date, on: :create, :unless => ->{ occured_at.present? }

  def self.doubles_matches
    joins(:winner).where(:opponents => {:type => Team.name})
  end

  def self.singles_matches
    joins(:winner).where(:opponents => {:type => Player.name})
  end

  def self.ordered(sort)
    self.order("occured_at #{sort.to_sym == :desc ? 'desc' : 'asc'}")
  end

  private

  def set_default_occured_at_date
    self.occured_at = Time.now
  end
end
