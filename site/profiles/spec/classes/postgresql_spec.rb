# frozen_string_literal: true

require 'spec_helper'

describe 'profiles::postgresql' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/srv/pg_dumps') }
        it { is_expected.to contain_class('postgresql::globals') }
        it { is_expected.to contain_class('postgresql::server') }
        it { is_expected.to contain_class('dbbackup') }
      end
    end
  end
end
