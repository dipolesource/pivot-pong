require 'spec_helper'

describe MatchesController do
  describe '#create' do
    let(:match_data) do
      {match: {winner: 'Bob', loser: 'Sally'}}
    end

    let(:errors) { ActiveModel::Errors.new('errors') }
    let(:match_validator) { instance_double(MatchValidator, valid?: true, errors: errors) }
    let(:match_form) { instance_double(MatchForm, save: true, as_json: match_data) }

    before do
      allow(controller).to receive(:new_match_form).and_return(match_form)
      allow(controller).to receive(:new_match_validator).and_return(match_validator)
    end

    context 'responds to html' do

      describe 'success' do
        it 'does the same thing' do
          post :create, match_data

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be_blank
          expect(assigns(:match_form)).to eq(match_form)
        end
      end

      describe 'failure' do
        let(:errors) do
          err = ActiveModel::Errors.new(Match.new)
          err.add(:loser, 'I failed')

          err
        end
        let(:match_validator) { instance_double(MatchValidator, valid?: false, errors: errors) }
        let(:match_data) { {match: {invalid: "data"}} }

        it 'adds an alert to the flash' do
          post :create, match_data

          expect(response).to be_redirect
          expect(flash[:alert]).to be_present
          expect(assigns(:match_form)).to eq(match_form)
        end
      end
    end

    context 'responds to json' do

      describe 'success' do

        it 'works' do
          xhr :post, :create, match_data

          expect(response).to be_success
          expect(response.body).to eq(match_data.to_json)
        end
      end

      describe 'failure' do
        let(:errors) { ActiveModel::Errors.new('errors').add(:bad_news, 'I failed') }
        let(:match_validator) { instance_double(MatchValidator, valid?: false, errors: errors) }
        let(:match_data) { {match: {invalid: "data"}} }

        it 'includes an error key in the response' do
          xhr :post, :create, match_data

          expect(response.status).to be(400)
          expect(response.body).to eq(match_data.merge(errors: errors).to_json)
        end
      end
    end
  end

  describe '#index' do
    let(:match_1) { MatchWithNamesStruct.new(1, 'bob', 'templeton', 'Bob', 'Templeton', Time.now) }
    let(:match_2) { MatchWithNamesStruct.new(2, 'bob', 'sally', 'Bob', 'Sally', Time.now) }
    let(:match_3) { MatchWithNamesStruct.new(3, 'sally', 'templeton', 'Sally', 'Templeton', Time.now) }
    let(:recent_matches) { [match_1, match_3] }
    let(:all_matches) { [match_1, match_2, match_3] }
    let(:tournament) { Tournament.new }
    let(:test_page_hash) { { page: 'page', matches: all_matches } }
    let(:match_finder_double) { double(MatchFinder, find_matches_for_tournament: true, find_page_of_matches: test_page_hash) }

    before do
      expect(controller).to receive(:match_finder) { match_finder_double }
      allow(controller).to receive(:tournament) { tournament }
    end

    context 'responds with json' do
      it 'returns all matches' do
        xhr :get, :index

        expected = all_matches.map{ |match| MatchPresenter.new(match).as_json }

        expect(response).to be_success
        expect(response.body).to eq({ 'results' => expected }.to_json)
      end

      it 'returns a list of recent matches' do
        expect(match_finder_double).to receive(:find_matches_for_tournament).with(tournament.start_time, tournament.end_time, described_class::TOURNAMENT_MATCHES_LIMIT).and_return(recent_matches)
        xhr :get, :index, recent: 'true'

        expected = recent_matches.map{ |match| MatchPresenter.new(match).as_json }

        expect(response).to be_success
        expect(response.body).to eq({ 'results' => expected }.to_json)
      end
    end

    context 'responds with html' do
      it 'is successful' do
        get :index

        expect(response).to be_success
        expect(assigns[:matches_presenter].length).to eq 3
        first_match = assigns[:matches_presenter][0]
        expect(first_match.winner_name).to eq 'Bob'
        expect(first_match.loser_name).to eq 'Templeton'
        expect(first_match.human_readable_time).to eq 'less than a minute ago'
        expect(assigns[:page]).to eq 'page'
      end
    end

  end
end
