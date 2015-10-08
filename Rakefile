require 'rspec/core/rake_task'

namespace :testenv do
  task :package do
    Bundler.with_clean_env do
      sh('bundle package --all')
    end
  end

  desc 'Setup the virtual machines for testing'
  task :setup => ['testenv:package'] do
    hiera = 'spec/integration/dopi/hiera.yaml'
    plan = 'spec/integration/dopi/build_dop_test_environment.yaml'
    sh("bundle exec bin/dopi --verbosity debug --hiera_yaml #{hiera} oneshot #{plan}")
  end

  desc 'Sync the current DOPi to the test environment'
  task :sync => ['testenv:package'] do
    sh('vagrant rsync puppetmaster.example.com')
  end
end

RSpec::Core::RakeTask.new('spec')

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
end

task :default => :spec

