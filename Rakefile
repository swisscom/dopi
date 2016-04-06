require 'rspec/core/rake_task'

namespace :spec do
  desc 'setup the test environment (this builds multiple virtual machines with vagrant and virtualbox)'
  task :prep do
    Bundler.with_clean_env do
      hiera = 'spec/fixtures/puppet/hiera.yaml'
      plan  = 'spec/fixtures/testenv_plan.yaml'
      sh('bundle package --all')
      sh("bundle exec bin/dopi --verbosity debug --trace --hiera_yaml #{hiera} oneshot #{plan}")
    end
  end

  desc 'destory the test environment'
  task :clean do
    Bundler.with_clean_env do
      sh('vagrant destroy')
    end
  end

  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
end

task :default => :spec

