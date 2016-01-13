require 'spec_helper'

Dopi.configuration.ssh_pass_auth = true
Dopi.configuration.mco_config    = 'spec/integration/dopi/mco_client.cfg'
Dopi.configuration.hiera_yaml    = 'spec/integration/dopi/hiera.yaml'

describe 'Basic integration test built from plan files' do

  # Create plugin tests from plugin test yaml files
  # and check if they run successfully
  Dir['spec/integration/dopi/plans/**/*.yaml'].each do |plan_file|
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
            expect(step.state_done?).to be true
          end
        end
      end
    end
  end

  # Create plugin tests from plugin test yaml files
  # and check if they fail
  Dir['spec/integration/dopi/fail_check_plans/**/*.yaml'].each do |plan_file|
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
            expect(step.state_failed?).to be true
          end
        end
      end
    end
  end

  # Create plugin tests from plugin test yaml files
  # and check if they are not valid
  Dir['spec/integration/dopi/invalid_plans/**/*.yaml'].each do |plan_file|
    describe plan_file do
      plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
      plan = Dopi::Plan.new(plan_parser)
      it "is not a valid plan file" do
        expect(plan.valid?).to be false
      end
    end
  end

end
