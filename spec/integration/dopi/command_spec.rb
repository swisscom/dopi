require 'spec_helper'

describe 'Basic integration test built from plan files' do
  #Dopi.log.level = ::Logger::INFO

  before :all do
    Dopi.configuration.ssh_pass_auth = true
    Dopi.configuration.mco_config    = 'spec/data/mco/client.cfg'

    # Setup test machines
    setup_plan = 'spec/integration/dopi/build_vagrant_test_environment_plan.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(setup_plan))
    plan = Dopi::Plan.new(plan_parser, 'fakeid')
    plan.run
  end

  # Create plugin tests from plugin test yaml files
  Dir['spec/integration/dopi/plans/**/*.yaml'].each do |plan_file|
    describe "plugin tests from: '#{plan_file}'" do
        plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
        plan = Dopi::Plan.new(plan_parser, 'fakeid')
        it "is a valid plan file" do
          expect(plan.valid?).to be true
        end
        plan.steps.each do |step|
        it "successfully runs the step: '#{step.name}'" do
          step.run(plan.max_in_flight)
          expect(step.state_done?).to be true
        end
      end
    end
  end

end
