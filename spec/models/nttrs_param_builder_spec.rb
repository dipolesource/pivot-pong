require 'spec_helper'

describe NttrsParamBuilder do
  subject { NttrsParamBuilder.new }

  describe '#build_player_data' do
    let(:bob) { PlayerStruct.new('bob', 'Bob', 2300, 23) }
    let(:sally) { PlayerStruct.new('sally', 'Sally', 1850, 40) }
    let(:templeton) { PlayerStruct.new('templeton', 'Templeton', nil, nil) }

    it 'returns data in the format the Nttrs gem expects' do
      expected_params = [
          {id: 'templeton', law: {mean: 1400, sigma: 450}},
          {id: 'sally', law: {mean: 1850, sigma: 40}},
          {id: 'bob', law: {mean: 2300, sigma: 23}},
      ]

      expect(subject.build_player_data([bob, sally, templeton])).to match_array(expected_params)
    end
  end

  describe '#build_match_data' do
    let(:match_1_time) { Time.new(2012, 12, 12) }
    let(:match_1) { Match.new(winner_key: 'bob', loser_key: 'sally', created_at: match_1_time) }

    let(:match_2_time) { Time.new(2012, 1, 1) }
    let(:match_2) { Match.new(winner_key: 'sally', loser_key: 'templeton', created_at: match_2_time) }

    it 'returns data in the format the Nttrs gem expects' do
      expected_params = {
          matches: [
              { time: match_1_time.to_i, winner_id: 'bob', loser_id: 'sally' },
              { time: match_2_time.to_i, winner_id: 'sally', loser_id: 'templeton' },
          ]
      }

      expect(subject.build_match_data([match_1, match_2])).to eq expected_params
    end
  end

end