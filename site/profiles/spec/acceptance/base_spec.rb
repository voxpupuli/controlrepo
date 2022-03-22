# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'profiles::base' do
  context 'with defaults' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        'include profiles::base'
      end
    end
    # rubocop:disable RSpec/RepeatedExampleGroupBody
    describe package('htop') do
      it { is_expected.to be_installed }
    end

    describe package('make') do
      it { is_expected.to be_installed }
    end

    describe package('gcc') do
      it { is_expected.to be_installed }
    end

    describe package('build-essential') do
      it { is_expected.to be_installed }
    end

    describe package('ctop') do
      it { is_expected.to be_installed }
    end

    describe package('ca-certificates') do
      it { is_expected.to be_installed }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end
end
