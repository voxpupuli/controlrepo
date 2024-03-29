# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'profiles::nginx' do
  context 'with defaults' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        'include profiles::nginx'
      end
    end
    describe package('nginx') do
      it { is_expected.to be_installed }
    end

    describe service('nginx') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
