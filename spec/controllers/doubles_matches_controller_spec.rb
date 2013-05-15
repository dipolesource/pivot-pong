require 'spec_helper'

describe DoublesMatchesController do
  describe '#index' do
    it 'shows a list of doubles matches' do
      create(:match)
      m1 = create(:doubles_match)
      m2 = create(:doubles_match)

      get :index
      expect(assigns[:matches]).to_not be_nil
      expect(assigns[:matches]).to match_array([m1, m2])

      assigns(:match).should be_new_record
      response.body.should include("<td>#{m1.winner}</td>")
    end
  end

  describe 'GET rankings' do
    let(:team_1) { FactoryGirl.create(:team) }
    let(:team_2) { FactoryGirl.create(:team) }

    before do
      Match.create winner: team_1, loser: team_2
    end

    it 'list teams by point ranking' do
      get :rankings

      response.should be_success
      assigns(:rankings).should == [[team_1, 8]]
    end
  end

  describe 'create' do
    let(:params) {
      {
          winner: {
              player1: { name: "Dave" },
              player2: { name: "Britz" }
          },
          loser: {
              player1: { name: "Bob" },
              player2: { name: "Sally" }
          }
      }
    }

    it 'builds a new doubles match' do
      expect {
      expect {
      expect {
        post :create, :match => params
      }.to change { Match.count }.by(1)
      }.to change { Player.count }.by(4)
      }.to change { Team.count }.by(2)
    end

    it 'handles case differences' do
      create(:player, :name => 'Dave')
      create(:player, :name => 'Britz')
      create(:player, :name => 'Bob')
      create(:player, :name => 'Sally')
      expect {
        expect {
          expect {
            post :create, :match => params
          }.to change { Match.count }.by(1)
        }.to change { Player.count }.by(0)
      }.to change { Team.count }.by(2)
    end

  end
end