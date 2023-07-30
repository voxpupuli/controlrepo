require 'ra10ke'
require 'metadata_json_deps'

Ra10ke::RakeTask.new do |t|
  # install modules into site/, so they are next to our profiles
  t.moduledir = File.join(Dir.pwd, 'site')
end

desc 'Run metadata-json-deps'
task :metadata_deps do
  files = FileList['site/*/metadata.json']
  # pull modules if they do not exist already
  Rake::Task['r10k:install'].invoke if files.count == 1
  files = FileList['site/profiles/metadata.json']
  MetadataJsonDeps::run(files)
end
