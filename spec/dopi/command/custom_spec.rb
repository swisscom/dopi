require 'spec_helper'

describe Dopi::Command do

  before :each do
    plan_file = 'spec/data/plan/plan_simple.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser, 'fakeid')
    @node = @plan.nodes.find {|node| node.name == 'web01.example.com'}
  end

  describe '#env' do
    it 'should return an empty hash if nothing is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.env).to eq({})
    end
    it 'should return a correct hash if it is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :env => {'MYVAR' => 'MYVALUE'}})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.env).to eq({'MYVAR' => 'MYVALUE'})
    end
    it 'will raise and error if env is not a hash' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :env => 2})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.env}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#arguments' do
    it 'should return an empty hash if nothing is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.arguments).to eq("")
    end
    it 'should return a correct string if arguments are specified as a String' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :arguments => "my custom arguments"})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.arguments).to eq("my custom arguments")
    end
    it 'should return a correct string if arguments are specified as an Array' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :arguments => ['my', 'custom', 'arguments']})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.arguments).to eq("my custom arguments")
    end
    it 'should return a correct string if arguments are specified as a Hash' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :arguments => {'my' =>  'custom', 'arguments' => ''}})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.arguments).to eq("my custom arguments ")
    end
    it 'will raise and error if arguments is not a String, Array or Hash' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :arguments => 2})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.arguments}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#expect_exit_codes' do
    pending
  end

end
