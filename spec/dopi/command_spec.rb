require 'spec_helper'

describe Dopi::Command do

  before :each do
    plan_file = 'spec/data/plan/plan_simple.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser, 'fakeid')
    @node = @plan.nodes.find {|node| node.name == 'web01.example.com'}
  end

  describe '#create_plugin_instance' do
    it 'takes a plugin name, a node and a command parser and returns a command plugin' do
      command_parser = DopCommon::Command.new('dummy')
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command).to be_a_kind_of Dopi::Command
      command_parser = DopCommon::Command.new({:plugin => 'dummy'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command).to be_a_kind_of Dopi::Command
    end
  end

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
