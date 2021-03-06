require 'spec_helper'

describe RatingsUpdater do
  let(:ratings_updater) { RatingsUpdater.new }
  let(:winner) { double :player, key: 'fe6467411b7b93fc5dfca7b8fa715a7d', name: 'Winner', mean: 1233, sigma: 12 }
  let(:loser) { double :player, key: 'e8bd17d7852ffa79a687933d1bfdac5a', name: 'Loser', mean: 445, sigma: 233 }
  let(:winner_rating) { double(Saulabs::TrueSkill::Rating, mean: 3454.45, deviation: 32.86) }
  let(:loser_rating) { double(Saulabs::TrueSkill::Rating, mean: 433, deviation: 12) }
  let(:factor_graph_double) { double(Saulabs::TrueSkill::FactorGraph, update_skills: true)}

  describe '#update_for_match' do
    it 'updates player rating with TrueSkill calculation' do
      expect(Saulabs::TrueSkill::Rating).to receive(:new).with(1233, 12).and_return(winner_rating)
      expect(Saulabs::TrueSkill::Rating).to receive(:new).with(445, 233).and_return(loser_rating)
      expect(Saulabs::TrueSkill::FactorGraph).to receive(:new).with({[winner_rating] => 1, [loser_rating] => 2}).and_return(factor_graph_double)
      expect(factor_graph_double).to receive(:update_skills)
      expect(winner).to receive(:update_attributes).with(mean: 3454, sigma: 33)
      expect(loser).to receive(:update_attributes).with(mean: 433, sigma: 12)

      ratings_updater.update_for_match(winner: winner, loser: loser)
    end
  end
end
