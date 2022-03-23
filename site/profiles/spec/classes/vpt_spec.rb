# frozen_string_literal: true

require 'spec_helper'

describe 'profiles::vpt' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/nginx/sites-available/kibana.voxpupu.li.conf').with_ensure('file') }
        it { is_expected.to contain_file('/etc/nginx/sites-available/voxpupu.li.conf').with_ensure('file') }
        it { is_expected.to contain_file('/etc/nginx/sites-available/sentry.voxpupu.li.conf').with_ensure('file') }
        it { is_expected.to contain_file('/etc/nginx/sites-enabled/kibana.voxpupu.li.conf').with_ensure('link') }
        it { is_expected.to contain_file('/etc/nginx/sites-enabled/voxpupu.li.conf').with_ensure('link') }
        it { is_expected.to contain_file('/etc/nginx/sites-enabled/sentry.voxpupu.li.conf').with_ensure('link') }
      end
    end
  end
end
