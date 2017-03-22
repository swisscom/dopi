require 'spec_helper'

DopCommon.config.mco_config    = 'spec/fixtures/mco_client.cfg'
DopCommon.config.hiera_yaml    = 'spec/fixtures/puppet/hiera.yaml'

describe 'Basic integration test built from plan files' do

  # Create plugin tests from plugin test yaml files
  # and check if they run successfully
  Dir['spec/integration/dopi/plans/**/*.yaml'].each do |plan_file|
    describe plan_file do
      plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
      plan = Dopi::Plan.new(plan_parser)
      node_names = plan.nodes.map{|n| n.name}
      plan.instance_variable_set(:@context_logger, DopCommon::ThreadContextLogger.new('/tmp/dopi_test', node_names))
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

  # Create plugin tests from plugin test yaml files
  # and check if they fail
  Dir['spec/integration/dopi/fail_check_plans/**/*.yaml'].each do |plan_file|
    describe plan_file do
      plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
      plan = Dopi::Plan.new(plan_parser)
      node_names = plan.nodes.map{|n| n.name}
      plan.instance_variable_set(:@context_logger, DopCommon::ThreadContextLogger.new('/tmp/dopi_test', node_names))
      it "is a valid plan file" do
        expect(plan.valid?).to be true
      end
      plan.step_sets.each do |step_set|
        step_set.steps.each do |step|
          it "successfully runs the step: '#{step.name}'" do
            step.run({:run_for_nodes => :all, :noop => false})
            expect(step.state).to be :failed
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
      node_names = plan.nodes.map{|n| n.name}
      plan.instance_variable_set(:@context_logger, DopCommon::ThreadContextLogger.new('/tmp/dopi_test', node_names))
      it "is not a valid plan file" do
        expect(plan.valid?).to be false
      end
    end
  end

end
