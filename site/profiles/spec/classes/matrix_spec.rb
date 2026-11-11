# frozen_string_literal: true

require 'spec_helper'

describe 'profiles::matrix' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      # Everything roles::matrix_server wires in next to this profile,
      # plus profiles::nftables (the base class every node gets via
      # profiles::base) so the nftables rule classes can resolve.
      let :pre_condition do
        [
          'include profiles::nftables',
          'include nftables::rules::http',
          'include nftables::rules::https',
          'include profiles::docker',
          'include profiles::lets_encrypt',
          'include profiles::nginx',
        ]
      end

      let :params do
        {
          sensitive_postgres_password: sensitive('postgres-pw'),
          sensitive_macaroon_secret_key: sensitive('macaroon-key'),
          sensitive_form_secret: sensitive('form-secret'),
          sensitive_registration_shared_secret: sensitive('registration-secret'),
          sensitive_s3_access_key: sensitive('s3-access'),
          sensitive_s3_secret_key: sensitive('s3-secret'),
          s3_bucket: 'synapse-media',
          s3_region: 'fsn1',
          s3_endpoint: 'https://fsn1.your-objectstorage.com',
        }
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_nftables__rule('default_out-matrix0') }

      it 'serves the delegation payloads as non-empty JSON' do
        expect(subject).to contain_file('/srv/voxpupuli.party/.well-known/matrix/server')
          .with_content(%r{"m\.server":\s*"matrix01\.voxpupu\.li:443"})
        expect(subject).to contain_file('/srv/voxpupuli.party/.well-known/matrix/client')
          .with_content(%r{"base_url":\s*"https://matrix01\.voxpupu\.li"})
      end

      it 'keeps homeserver.yaml readable by the container UID only' do
        expect(subject).to contain_file('/opt/matrix-synapse/config/synapse/homeserver.yaml')
          .with(owner: 991, group: 991, mode: '0400')
      end

      it 'provisions a config file for every worker in the compose stack' do
        %w[generic_worker1 generic_worker2 generic_worker3 generic_worker4
           events_persister receipts_writer].each do |worker|
          expect(subject).to contain_file("/opt/matrix-synapse/config/synapse/workers/#{worker}.yaml")
            .with_content(%r{worker_name: #{worker}})
        end
      end

      # Workers answer 404 for client endpoints outside the documented
      # list and raise on stream endpoints they do not write, so the
      # catch-all has to be the main process.
      it 'routes client endpoints to the process that can serve them' do
        expect(subject).to contain_nginx__resource__location('matrix01.voxpupu.li client')
          .with(location: '/_matrix/client/', proxy: 'http://synapse_main')
        expect(subject).to contain_nginx__resource__location('matrix01.voxpupu.li client workers')
          .with(proxy: 'http://synapse_client')
          .with_location(%r{rooms/\.\*/send})
        expect(subject).to contain_nginx__resource__location('matrix01.voxpupu.li client stream writer')
          .with(proxy: 'http://synapse_stream_writer', priority: 450)
          .with_location(%r{rooms/\.\*/typing.*sendToDevice.*account_data.*receipt})
      end

      it 'gives the stream writer a client listener for those endpoints' do
        expect(subject).to contain_file('/opt/matrix-synapse/config/synapse/workers/receipts_writer.yaml')
          .with_content(%r{names: \[client, replication\]})
      end

      it { is_expected.to contain_docker_compose('matrix-synapse') }
    end
  end
end
