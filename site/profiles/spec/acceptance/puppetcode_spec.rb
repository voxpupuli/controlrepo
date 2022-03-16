# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'profiles::puppetcode' do
  context 'with defaults' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        'include profiles::puppetcode'
      end
    end
  end
end
