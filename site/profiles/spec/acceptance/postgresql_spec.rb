# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'profiles::postgresql' do
  context 'with defaults' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        'include profiles::postgresql'
      end
    end
    describe package('postgresql-13') do
      it { is_expected.to be_installed }
    end

    describe service('postgresql@13-main.service') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe port(5432) do
      it { is_expected.to be_listening.on('127.0.0.1').with('tcp') }
    end
  end
end
