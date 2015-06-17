require 'spec_helper'

describe Dopi::Command do

  before :each do
    plan_file = 'spec/data/plan/plan_simple.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser, 'fakeid')
    @node = @plan.nodes.find {|node| node.name == 'web01.example.com'}
  end

  describe '#exec' do
    it 'should return the exec value if specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :exec => 'echo'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.exec).to eq('echo')
    end
    it 'will raise and error if exec is not specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.exec}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if exec is not a String' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :exec => 2})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.exec}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#env' do
    it 'should return the defaults hash if nothing is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.env).to eq({'DOP_NODE_FQDN' => @node.name})
    end
    it 'should return the specified hash merged with the defaults' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :env => {'MYVAR' => 'MYVALUE'}})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.env).to eq({'DOP_NODE_FQDN' => @node.name, 'MYVAR' => 'MYVALUE'})
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
    it 'should return 0 if nothing is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.expect_exit_codes).to eq(0)
    end
    it 'should return a number if a number is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :expect_exit_codes => 3})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.expect_exit_codes).to eq(3)
    end
    it 'should return an Array of numbers if such an Array is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :expect_exit_codes => [0, 1, 3]})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.expect_exit_codes).to eq([0, 1, 3])
    end
    it 'should return "all" if such a String is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :expect_exit_codes => 'all'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.expect_exit_codes).to eq('all')
    end
    it 'will raise and error if the value is an invalid string' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :expect_exit_codes => 'foo'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.expect_exit_codes}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if the Array contains a String' do
      command_parser = DopCommon::Command.new({:plugin => 'custom', :expect_exit_codes => [1, 2, 'foo']})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.expect_exit_codes}.to raise_error Dopi::CommandParsingError
    end

  end

end
