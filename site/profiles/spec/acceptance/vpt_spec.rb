# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'profiles::vpt' do
  context 'with defaults' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        'class { "profiles::vpt": deploy_kibana => false, deploy_vpt => false, deploy_sentry => false }'
      end
    end
  end
end
