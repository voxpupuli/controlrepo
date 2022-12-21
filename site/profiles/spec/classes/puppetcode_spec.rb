# frozen_string_literal: true

require 'spec_helper'

describe 'profiles::puppetcode' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('r10k') }
        it { is_expected.to contain_ssh_keygen('root_github') }
        it { is_expected.to contain_ssh__client__config__user('root_github') }
      end
    end
  end
end
