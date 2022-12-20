# frozen_string_literal: true

require 'spec_helper'

describe 'profiles::certbot::nginx' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      let(:title) { 'example.com' }

      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_nginx__resource__location('= /.well-known/acme-challenge/ - example.com') }
        it { is_expected.to contain_nginx__resource__location('^~ /.well-known/acme-challenge/ - example.com') }
      end
    end
  end
end
