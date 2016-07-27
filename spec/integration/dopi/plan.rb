require 'spec_helper'

Dopi.configuration.mco_config    = 'spec/fixtures/mco_client.cfg'
Dopi.configuration.hiera_yaml    = 'spec/fixtures/puppet/hiera.yaml'

describe 'Run specific plan that should complete' do

  # Create plugin test from specific yaml file
  # and check it completes
  plan_file = "spec/integration/dopi/plans/#{ENV['DOPI_TEST_PLAN']}.yaml"
  describe plan_file do
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    plan = Dopi::Plan.new(plan_parser)
    it "is a valid plan file" do
      expect(plan.valid?).to be true
    end
    plan.step_sets.each do |step_set|
      step_set.steps.each do |step|
        it "successfully runs the step: '#{step.name}'" do
          step.run({:run_for_nodes => :all, :noop => false})
          expect(step.state).to be :done
        end
      end
    end
  end

end
