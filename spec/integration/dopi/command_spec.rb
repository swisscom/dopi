require 'spec_helper'

describe 'Basic integration tets' do

  # Create plugin tests from plugin test yaml files
  Dir['spec/data/plan/plugins/**/*.yaml'].each do |plan_file|
    describe "plugin tests from: '#{plan_file}'" do
      Dopi.configuration.ssh_pass_auth = true
      Dopi.configuration.mco_config = 'spec/data/mco/client.cfg'
      plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
      plan = Dopi::Plan.new(plan_parser, 'fakeid')
      plan.steps.each do |step|
        it "successfully runs the step: '#{step.name}'" do
          step.run(plan.max_in_flight)
          expect(step.state_done?).to be true
        end
      end
    end
  end

end
