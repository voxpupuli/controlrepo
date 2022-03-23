# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'profiles::postfix' do
  context 'with defaults' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        'include profiles::postfix'
      end
    end
    describe package('postfix') do
      it { is_expected.to be_installed }
    end

    describe service('postfix') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe port(25) do
      it { is_expected.to be_listening.on('0.0.0.0').with('tcp') }
    end
  end
end
