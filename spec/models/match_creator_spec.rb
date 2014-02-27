require 'spec_helper'

describe MatchCreator do
  subject(:creator) { MatchCreator.new }

  describe '#create_match(winner, loser)' do
    it 'adds a match record with the winner and loser' do
      expect {
        creator.create_match(winner_key: 'templeton', loser_key: 'sally')
      }.to change(Match, :count).by(1)

      expect(Match.last.winner_key).to eq('templeton')
      expect(Match.last.loser_key).to eq('sally')
    end

    it 'returns an Open Struct representing the match' do
      expect(creator.create_match(winner_key: 'sally', loser_key: 'bob')).to eq(OpenStruct.new(winner_key: 'sally', loser_key: 'bob'))
    end
  end
end