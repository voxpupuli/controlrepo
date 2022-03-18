# frozen_string_literal: true

require 'spec_helper'

describe 'profiles::grafana' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      let :node do
        'voxpupu.li'
      end

      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('grafana').with_require('Package[toml]') }
        it { is_expected.to contain_class('profiles::nginx') }
        it { is_expected.to contain_package('toml').with_provider('puppet_gem') }
        it { is_expected.to contain_nginx__resource__server('grafana.voxpupu.li') }
        it { is_expected.to contain_grafana_plugin('grafana-bigquery-datasource') }
      end
    end
  end
end
