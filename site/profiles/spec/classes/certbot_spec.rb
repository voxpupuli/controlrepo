# frozen_string_literal: true

require 'spec_helper'

describe 'profiles::certbot' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('certbot') }
        it { is_expected.to contain_service('certbot.timer') }
        it { is_expected.to contain_systemd__dropin_file('verbose.conf') }
      end
    end
  end
end
