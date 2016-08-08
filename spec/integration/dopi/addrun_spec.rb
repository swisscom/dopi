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
      plan_cache = DopCommon::PlanCache.new(Dopi.configuration.plan_cache_dir)
      it 'add plan to cache' do
        plan = Dopi.add_plan(plan_file)
        plan_name = plan.name
      end
      it 'load plan from cache' do
        plan = Dopi.load_plan(plan_name)
      end
      it 'run loaded plan' do
        Dopi.run_plan(plan, {})
      end
      it 'remove plan from cache' do
        plan_cache.remove(plan_name)
      end
    end
  end
end
