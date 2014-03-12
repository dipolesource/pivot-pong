require 'spec_helper'

feature 'On the dashboard:', :js do
  let(:bob) { Player.create(name: 'Bob', key: 'bob', mean: 2300, sigma: 35, last_tournament_date: 5.weeks.ago) }
  let(:sally) { Player.create(name: 'Sally', key: 'sally', mean: 2105, sigma: 60, last_tournament_date: 1.week.ago) }
  let(:godzilla) { Player.create(name: 'Godzilla', key: 'godzilla') }

  let(:match_1) { Match.create(winner_key: bob.key, loser_key: sally.key) }
  let(:match_2) { Match.create(winner_key: godzilla.key, loser_key: sally.key) }
  let(:match_3) { Match.create(winner_key: godzilla.key, loser_key: bob.key) }

  let(:create_players) { bob and sally and nil }
  let(:create_leaderboard_objects) { match_1 and match_2 and match_3 and nil }

  scenario 'a player can enter a match.' do |example|
    visit root_path

    step '1. fill in the winner and the loser', current: example do
      fill_in I18n.t('match.form.winner_label').upcase, with: 'Bob'
      fill_in I18n.t('match.form.loser_label').upcase, with: 'Templeton'

      click_on I18n.t('match.form.commit')
    end

    step '2. the last match results should update to reflect the entry', current: example do
      find('.recent-matches-link').click

      expect(page).to have_content(['Bob', I18n.t('match.last.win_verb'), 'Templeton'].join(' '))
    end
  end

  scenario 'a viewer can see all of the players and their data' do
    create_players
    visit root_path

    expect(page).to have_content('Bob')
    expect(page).to have_content(2300)

    expect(page).to have_content('Sally')
    expect(page).to have_content(2105)
  end

  scenario 'a viewer can see existing matches' do
    match_1
    visit root_path

    find('.recent-matches-link').click

    expect(page).to have_content "Bob #{I18n.t('match.last.win_verb')} Sally"
  end

  scenario 'a user can view player info' do
    match_1
    visit root_path

    expect(page).to have_content('Bob')

    # svg selection seems to generally suck on attributes, this is a work around
    page.execute_script "window.location = $('a').filter('[title=Bob]').first().attr('href');"

    within '#player_info' do
      expect(page).to have_content 'Bob'
      expect(page).to have_content '1-0 (100.0%)'
    end
  end

  scenario 'a viewer can see current tournament player rankings' do
    create_leaderboard_objects
    visit root_path

    find('.recent-matches-link').click
    expect(page).to have_content I18n.t('player.recent_matches.title').upcase
    expect(page).to_not have_content I18n.t('player.tournament_rankings.title').upcase

    find('.leaderboard-link').click
    expect(page).to have_content I18n.t('player.tournament_rankings.title').upcase
    expect(page).to_not have_content I18n.t('player.recent_matches.title').upcase

    expect(page).to have_content "Godzilla 2-0"
    expect(page).to have_content "Bob 1-1"
    expect(page).to have_content "Sally 0-2"
  end
end