# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'profiles::grafana' do
  context 'with defaults' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        'include profiles::grafana'
      end
    end
    describe package('grafana') do
      it { is_expected.to be_installed }
    end

    describe service('grafana-server') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe port(3001) do
      it { is_expected.to be_listening.on('127.0.0.1').with('tcp') }
    end
  end
end
