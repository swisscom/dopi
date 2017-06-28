require 'rspec/core/rake_task'

namespace :spec do
  desc 'setup the test environment (this builds multiple virtual machines with vagrant and virtualbox)'
  task :prep do
    Bundler.with_clean_env do
      sh('vagrant up')
      hiera = 'spec/fixtures/puppet/hiera.yaml'
      plan  = 'spec/fixtures/testenv_plan.yaml'
      sh('bundle package --all')
      sh("bundle exec bin/dopi --hiera_yaml #{hiera} oneshot #{plan}")
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

  desc 'Run single plan file from spec/integration/dopi/plans/<name>.yaml, <name> is taken from env DOPI_TEST_PLAN'
  RSpec::Core::RakeTask.new(:plan) do |t|
    t.pattern = 'spec/integration/dopi/plan.rb'
  end

  desc 'Run single plan file from spec/integration/dopi/fail_check_plans/<name>.yaml and expect it to fail, <name> is taken from env DOPI_TEST_PLAN'
  RSpec::Core::RakeTask.new(:failplan) do |t|
    t.pattern = 'spec/integration/dopi/failplan.rb'
  end
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

