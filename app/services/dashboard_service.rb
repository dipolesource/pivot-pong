module DashboardService
  extend self, BaseService

  def new_match
    MatchFactory.new
  end

  def tournament_rankings
    Tournament.new.determine_rankings
  end

  def collection_source
    Player.all
  end
end
