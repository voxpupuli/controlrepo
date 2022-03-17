# frozen_string_literal: true

require 'spec_helper'

describe 'profiles::grafana' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('grafana').with_require('Package[toml]') }
        it { is_expected.to contain_package('toml').with_provider('puppet_gem') }
      end
    end
  end
end
