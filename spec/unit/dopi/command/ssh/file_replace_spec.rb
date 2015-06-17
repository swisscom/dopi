require 'spec_helper'

describe Dopi::Command::Ssh::FileReplace do

  before :each do
    plan_file = 'spec/data/plan/plan_simple.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser, 'fakeid')
    @node = @plan.nodes.find {|node| node.name == 'web01.example.com'}
  end

  describe '#replacement' do
    it 'should return the replacement value if specified' do
      command_parser = DopCommon::Command.new({:plugin => 'ssh/file_replace', :replacement => 'foo'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.replacement).to eq('foo')
    end
    it 'will raise and error if replacement is not specified' do
      command_parser = DopCommon::Command.new({:plugin => 'ssh/file_replace'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.replacement}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if replacement is not a String' do
      command_parser = DopCommon::Command.new({:plugin => 'ssh/file_replace', :replacement => 2})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.replacement}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#global' do
    it 'should return true if nothing is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'ssh/file_replace'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.global).to be true
    end
    it 'should return the correct value if specified' do
      command_parser = DopCommon::Command.new({:plugin => 'ssh/file_replace', :global => false})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.global).to be false
    end
    it 'will raise and error if global is not a boolean' do
      command_parser = DopCommon::Command.new({:plugin => 'ssh/file_replace', :global => 2})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.global}.to raise_error Dopi::CommandParsingError
    end
  end

end
