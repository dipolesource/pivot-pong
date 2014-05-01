require 'spec_helper'
require_relative '../../lib/tasks/blue_green_deploy'

describe BlueGreenDeploy do
  let(:cf_manifest) { YAML.load_file('spec/tasks/manifest.yml') }
  let(:deploy_config) { BlueGreenDeployConfig.new(cf_manifest) }

  describe '#make_it_so' do
    context 'when blue/green is specified' do
      let(:app_name) { 'app_name' }
      let(:worker_apps) { ['app_name-worker'] }
      let(:domain) { 'cfapps.io' }
      let(:blue_or_green) { 'green' }
      let(:hot_url) { 'la-pong' }
      let(:current_hot_app) { 'blue' }
      subject { BlueGreenDeploy.make_it_so(domain, app_name, worker_apps, deploy_config, blue_or_green) }
      before do
        @cf_route_table = [
          Route.new("#{app_name}-blue", domain, "#{app_name}-blue"),
          Route.new("#{app_name}-green", domain, "#{app_name}-green"),
          Route.new(hot_url, domain, "#{app_name}-#{current_hot_app}")
        ]
        allow(CloudFoundry).to receive(:push)
        allow(CloudFoundry).to receive(:routes).and_return(@cf_route_table)
        allow(CloudFoundry).to receive(:unmap_route).with("#{app_name}-#{current_hot_app}", 'cfapps.io', hot_url) do
          @cf_route_table.delete_if { |route| route.app == "#{app_name}-#{current_hot_app}" && route.host == hot_url }
        end
        allow(CloudFoundry).to receive(:map_route) do |app, domain, host|
          @cf_route_table.delete_if { |route| route.host == host }
          @cf_route_table.push(Route.new(host, domain, app))
        end
      end

      it 'instructs Cloud Foundry to deploy the specified app' do
        expect(CloudFoundry).to receive(:push).with("#{app_name}-#{blue_or_green}")
        subject
      end

      it 'attempts to make that the hot app' do
        expect(BlueGreenDeploy).to receive(:make_hot).with(app_name, domain, deploy_config, blue_or_green)
        subject
      end
    end

    context 'when blue/green is omitted' do
      subject { BlueGreenDeploy.make_it_so(domain, app_name, worker_apps, deploy_config) }
      let(:app_name) { 'app_name' }
      let(:domain) { 'cfapps.io' }
      let(:worker_apps) { ['app_name-worker'] }
      let(:hot_url) { 'la-pong' }
      before do
        @cf_route_table = [
          Route.new("#{app_name}-blue", domain, "#{app_name}-blue"),
          Route.new("#{app_name}-green", domain, "#{app_name}-green"),
          Route.new(hot_url, domain, "#{app_name}-#{current_hot_app}")
        ]
        allow(CloudFoundry).to receive(:push)
        allow(CloudFoundry).to receive(:routes).and_return(@cf_route_table)
        allow(CloudFoundry).to receive(:unmap_route).with("#{app_name}-#{current_hot_app}", 'cfapps.io', hot_url) do
          @cf_route_table.delete_if { |route| route.app == "#{app_name}-#{current_hot_app}" && route.host == hot_url }
        end
        allow(CloudFoundry).to receive(:map_route) do |app, domain, host|
          @cf_route_table.delete_if { |route| route.host == host }
          @cf_route_table.push(Route.new(host, domain, app))
        end
      end

      context 'green is the current hot app' do
        let(:current_hot_app) { 'green' }

        it 'makes blue the current hot app' do
          subject
          route_to_hot_app = @cf_route_table.find { |route| route.host == hot_url }
          expect(route_to_hot_app.app).to eq "#{app_name}-blue"
        end
      end

      context 'blue is the current hot app' do
        let(:current_hot_app) { 'blue' }

        it 'makes green the current hot app' do
          subject
          route_to_hot_app = @cf_route_table.find { |route| route.host == hot_url }
          expect(route_to_hot_app.app).to eq "#{app_name}-green"
        end
      end

    end
  end

  describe '#ready_for_takeoff' do
    subject { BlueGreenDeploy.ready_for_takeoff(hot_app_name, hot_url, blue_or_green) }
    let(:app_name) { 'app_name' }
    let(:domain) { 'cfapps.io' }
    let(:blue_or_green) { 'green' }
    let(:hot_url) { 'la-pong' }
    let(:hot_app_name) { "#{app_name}-#{current_hot_app}" }
    before do
      @cf_route_table = [
        Route.new("#{app_name}-blue", domain, "#{app_name}-blue"),
        Route.new("#{app_name}-green", domain, "#{app_name}-green"),
        Route.new(hot_url, domain, "#{app_name}-#{current_hot_app}")
      ]
      allow(CloudFoundry).to receive(:push)
      allow(CloudFoundry).to receive(:routes).and_return(@cf_route_table)
      allow(CloudFoundry).to receive(:unmap_route).with("#{app_name}-#{current_hot_app}", 'cfapps.io', hot_url) do
        @cf_route_table.delete_if { |route| route.app == "#{app_name}-#{current_hot_app}" && route.host == hot_url }
      end
      allow(CloudFoundry).to receive(:map_route) do |app, domain, host|
        @cf_route_table.delete_if { |route| route.host == host }
        @cf_route_table.push(Route.new(host, domain, app))
      end
    end

    context 'the target color is opposite of what`s already hot' do
      let(:current_hot_app) { 'blue' }
      it 'does not raise an error: "It`s kosh!"' do
        expect{ subject }.to_not raise_error
      end

    end

    context 'the target color matches what`s already hot' do
      let(:current_hot_app) { 'green' }
      it 'raises an InvalidRouteStateError' do
        expect{ subject }.to raise_error(InvalidRouteStateError)
      end
    end

    context 'when blue/green is omitted' do
      let(:blue_or_green) { nil }
      context 'there is no current hot app' do
        let(:current_hot_app) { '' }
        let(:hot_app_name) { nil }
        before do
          @cf_route_table.pop # remove the hot route
        end

        it 'raises an InvalidRouteStateError' do
          expect{ subject }.to raise_error(InvalidRouteStateError)
        end
      end
    end
  end

  describe '#get_hot_app' do
    subject { BlueGreenDeploy.get_hot_app(hot_url) }
    let(:hot_app) { 'app_name-green' }
    let(:hot_url) { 'la-pong' }
    let(:routes) {
      [
        Route.new('app_name-blue', 'cfapps.io', 'app_name-blue'),
        Route.new('app_name-green', 'cfapps.io', 'app_name-green'),
        Route.new(hot_url, 'cfapps.io', hot_app)
      ]
    }

    before do
      allow(CloudFoundry).to receive(:routes).and_return(routes)
    end

    it 'returns the app mapped to that Host URL' do
      expect(subject).to eq hot_app
    end

    context 'when there is no app mapped to the hot url' do
      let(:routes) {
        [
          Route.new('app_name-blue', 'cfapps.io', 'app_name-blue'),
          Route.new('app_name-green', 'cfapps.io', 'app_name-green'),
        ]
      }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end


  describe '#make_hot' do
    let(:app_name) { 'app_name' }
    let(:target_app) { 'blue' }
    let(:current_hot_app) { 'green' }
    let(:hot_url) { 'la-pong' }
    subject { BlueGreenDeploy.make_hot(app_name, 'cfapps.io', deploy_config, target_app) }

    before do
      @cf_route_table = [
        Route.new('app_name-blue', 'cfapps.io', 'app_name-blue'),
        Route.new('app_name-green', 'cfapps.io', 'app_name-green'),
        Route.new(hot_url, 'cfapps.io', "#{app_name}-#{current_hot_app}")
      ]
      allow(CloudFoundry).to receive(:push)
      allow(CloudFoundry).to receive(:routes).and_return(@cf_route_table)
      allow(CloudFoundry).to receive(:unmap_route).with("#{app_name}-#{current_hot_app}", 'cfapps.io', hot_url) do
        @cf_route_table.delete_if { |route| route.app == "#{app_name}-#{current_hot_app}" && route.host == hot_url }
      end
      allow(CloudFoundry).to receive(:map_route) do |app, domain, host|
        @cf_route_table.delete_if { |route| route.host == host }
        @cf_route_table.push(Route.new(host, domain, app))
      end
    end

    context 'when there is no current hot app' do
      before do
        @cf_route_table.pop  # remove the "hot url" route
      end

      it 'the target_app is mapped to the hot_url' do
        subject
        expect(BlueGreenDeploy.get_hot_app(hot_url)).to eq "app_name-#{target_app}"
      end
    end

    context 'when there IS a hot URL route, but it is not mapped to any app' do
      before do
        @cf_route_table.pop  # remove the "hot url" route
        @cf_route_table.push(Route.new(hot_url, 'cfapps.io', nil))
      end

      it 'the target_app is mapped to the hot_url' do
        subject
        expect(BlueGreenDeploy.get_hot_app(hot_url)).to eq "app_name-#{target_app}"
      end
    end

    context 'when the hot url IS mapped to an app, already' do
      it 'the app that was mapped to the hot_url is no longer mapped to hot_url' do
        subject
        expect(BlueGreenDeploy.get_hot_app(hot_url)).to_not eq "app_name-#{current_hot_app}"
      end

      it 'the target_app is mapped to the hot_url' do
        subject
        expect(BlueGreenDeploy.get_hot_app(hot_url)).to eq "app_name-#{target_app}"
      end
    end
  end
end