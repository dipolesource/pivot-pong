class PlayerPresenter
  include ActionView::Helpers::NumberHelper

  def initialize(player, matches, recent_matches, tournament_wins)
    @player = player
    @matches = matches
    @recent_matches = recent_matches
    @tournament_wins = tournament_wins
  end

  attr_reader :player

  def overall_winning_percentage
    percent = 100.0 * wins(@matches).count / @matches.count
    number_to_percentage(percent, precision: 1)
  end

  def overall_losses
    losses(@matches).count
  end

  def overall_wins
    wins(@matches).count
  end

  def overall_record_string
    "#{overall_wins}-#{overall_losses}"
  end

  def tournament_win_count
    @tournament_wins.count
  end

  def current_streak_type
    string_map = {
        'winner' => I18n.t('player.streak.type.winner'),
        'loser' => I18n.t('player.streak.type.loser'),
    }
    string_map[streak_type(@matches, @player)]
  end

  def current_streak_count
    type = streak_type(@matches, @player)
    streak_count(@matches, @player, type)
  end

  def current_streak_string
    return '' unless @matches.first

    "#{current_streak_count}#{current_streak_type}"
  end

  def current_streak_totem_image
    type = current_streak_type
    count = current_streak_count

    if type == 'W'
      return 'smoke.png' if count == 2
      return 'fire.png' if count > 2
    elsif type == 'L'
      return 'ice.png' if count > 2
    end

    return ''
  end

  def name
    @player.name
  end

  def recent_matches
    @recent_matches.map do |match|
      if match.winner_key == @player.key
        result = "#{I18n.t('player.recent_matches.won')} #{match.loser_name}"
      else
        result = "#{I18n.t('player.recent_matches.lost')} #{match.winner_name}"
      end

      "#{result} #{I18n.t('player.recent_matches.on_date')} #{match.created_at.to_s(:pivot_pong_time)}"
    end
  end

  def as_json
    {
        name: name,
        overall_losses: overall_losses,
        overall_wins: overall_wins,
        current_streak_count: current_streak_count,
        current_streak_type: current_streak_type,
        current_streak_totem_image: current_streak_totem_image,
        rating: @player.mean,
        overall_winning_percentage: overall_winning_percentage,
    }
  end

  private

  def wins(matches)
    matches.select { |match| match.winner_key == @player.key }
  end

  def losses(matches)
    matches.select { |match| match.loser_key == @player.key }
  end

  def streak_count(matches, player, type)
    return nil unless matches.first

    streak = 1
    matches.each_with_index do |match, index|
      if match.send("#{type}_key") == player.key
        streak = index + 1
      else
        break
      end
    end

    streak
  end

  def streak_type(matches, player)
    return nil unless matches.first

    if matches.first.winner_key == player.key
      'winner'
    else
      'loser'
    end
  end

end