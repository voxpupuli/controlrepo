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

      it 'hands the media eviction job its bucket settings through .env' do
        expect(subject).to contain_file('/opt/matrix-synapse/.env')
          .with(mode: '0600')
          .with_content(sensitive(%r{^AWS_ACCESS_KEY_ID=s3-access$}))
          .with_content(sensitive(%r{^AWS_SECRET_ACCESS_KEY=s3-secret$}))
          .with_content(sensitive(%r{^S3_BUCKET=synapse-media$}))
          .with_content(sensitive(%r{^S3_ENDPOINT=https://fsn1\.your-objectstorage\.com$}))
      end

      it { is_expected.to contain_docker_compose('matrix-synapse') }

      # Without certificates the vhosts are plain HTTP, which is all a
      # default compile sees. This is the catalog of every run after the
      # first one, once certbot has populated the fact.
      context 'once the certificates exist' do
        let :facts do
          os_facts.merge(
            letsencrypt_directory: {
              'voxpupuli.party' => '/etc/letsencrypt/live/voxpupuli.party',
              'matrix01.voxpupu.li' => '/etc/letsencrypt/live/matrix01.voxpupu.li',
            },
          )
        end

        it { is_expected.to compile.with_all_deps }

        it 'serves both vhosts over TLS with their own certificate' do
          expect(subject).to contain_nginx__resource__server('voxpupuli.party')
            .with(ssl: true, ssl_cert: '/etc/letsencrypt/live/voxpupuli.party/fullchain.pem')
          expect(subject).to contain_nginx__resource__server('matrix01.voxpupu.li')
            .with(ssl: true, ssl_cert: '/etc/letsencrypt/live/matrix01.voxpupu.li/fullchain.pem',
                  ssl_cache: 'shared:SSL:10m')
        end

        it 'puts the API and the delegation files in the TLS server blocks' do
          expect(subject).to contain_nginx__resource__location('matrix01.voxpupu.li client')
            .with(ssl: true, ssl_only: true)
          expect(subject).to contain_nginx__resource__location('matrix01.voxpupu.li federation')
            .with(ssl: true, ssl_only: true)
          expect(subject).to contain_nginx__resource__location('voxpupuli.party matrix well-known')
            .with(ssl: true)
          # the fragment the module writes into the TLS block for /_matrix/client/
          expect(subject).to contain_concat__fragment('matrix01.voxpupu.li-800-799e0fbf9b49afdd70084167b0660822-ssl')
            .with_content(%r{proxy_pass\s+http://synapse_main;})
        end
      end

      # Where matrix01 is today: the delegation vhost has had its
      # certificate since March, the Matrix host has never had one.
      context 'with a certificate for the delegation name only' do
        let :facts do
          os_facts.merge(letsencrypt_directory: { 'voxpupuli.party' => '/etc/letsencrypt/live/voxpupuli.party' })
        end

        it { is_expected.to compile.with_all_deps }

        it 'serves the delegation over TLS and the API on port 80 until its certificate arrives' do
          expect(subject).to contain_nginx__resource__server('voxpupuli.party').with(ssl: true)
          expect(subject).to contain_nginx__resource__server('matrix01.voxpupu.li').with(ssl: false)
          expect(subject).to contain_nginx__resource__location('voxpupuli.party matrix well-known').with(ssl: true)
          expect(subject).to contain_nginx__resource__location('matrix01.voxpupu.li client')
            .with(ssl: false, ssl_only: false)
          expect(subject).to contain_letsencrypt__certonly('matrix01.voxpupu.li')
        end
      end

      context 'with other names than the production ones' do
        let :params do
          super().merge(server_name: 'example.org', matrix_domain: 'matrix.example.org')
        end

        it { is_expected.to compile.with_all_deps }

        it 'uses them for both vhosts, the delegation and the homeserver identity' do
          expect(subject).to contain_nginx__resource__server('example.org')
          expect(subject).to contain_nginx__resource__server('matrix.example.org')
          expect(subject).to contain_letsencrypt__certonly('matrix.example.org')
          expect(subject).to contain_file('/srv/example.org/.well-known/matrix/server')
            .with_content(%r{"m\.server":\s*"matrix\.example\.org:443"})
          expect(subject).to contain_file('/opt/matrix-synapse/config/synapse/homeserver.yaml')
            .with_content(sensitive(%r{^server_name: "example\.org"$}))
            .with_content(sensitive(%r{^public_baseurl: "https://matrix\.example\.org"$}))
            .with_content(sensitive(%r{^signing_key_path: /data/example\.org\.signing\.key$}))
          expect(subject).to contain_file('/opt/matrix-synapse/.env')
            .with_content(sensitive(%r{^SYNAPSE_SERVER_NAME=example\.org$}))
        end

        it { is_expected.not_to contain_nginx__resource__server('voxpupuli.party') }
      end
    end
  end
end
