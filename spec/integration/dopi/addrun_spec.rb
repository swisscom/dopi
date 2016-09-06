require 'spec_helper'

# Try running the plan when it is added (persisted to disk) and loaded again
# before running.

Dopi.configuration.mco_config = 'spec/fixtures/mco_client.cfg'
Dopi.configuration.hiera_yaml = 'spec/fixtures/puppet/hiera.yaml'

plan_file = "spec/integration/dopi/plans/dummy.yaml"
plan_name = nil
plan = nil

describe 'running an added plan' do
  context 'in temp directory' do
    Dir.mktmpdir do |tmp|
      Dopi.configuration.plan_cache_dir = tmp
      it 'add plan to cache' do
        plan_name = Dopi.add(plan_file)
      end
      it 'load plan from cache' do
        plan = Dopi.show(plan_name)
      end
      it 'run loaded plan' do
        Dopi.run(plan_name, true, {})
      end
      it 'remove plan from cache' do
        Dopi.remove(plan_name)
      end
    end
  end
end
