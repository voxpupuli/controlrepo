# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'profiles::node_exporter' do
  context 'with defaults' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        'include profiles::node_exporter'
      end
    end
  end
end
