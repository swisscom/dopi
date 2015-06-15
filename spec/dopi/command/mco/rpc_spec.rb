require 'spec_helper'
require 'mcollective'

describe Dopi::Command::Mco::Rpc do

  before :each do
    plan_file = 'spec/data/plan/plan_simple.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser, 'fakeid')
    @node = @plan.nodes.find {|node| node.name == 'web01.example.com'}
  end

  describe '#agent' do
    it 'should return the name of the agent if it is specified' do
      command_parser = DopCommon::Command.new({:plugin => 'mco/rpc', :agent => 'rpcutil'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.agent).to eq('rpcutil')
    end
    it 'will raise and error if agent is not specified and valid' do
      command_parser = DopCommon::Command.new({:plugin => 'mco/rpc'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.agent}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if agent is not a String' do
      command_parser = DopCommon::Command.new({:plugin => 'mco/rpc', :agent => 2})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.agent}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if agent does not exists' do
      command_parser = DopCommon::Command.new({:plugin => 'mco/rpc', :agent => 'nonexistingagent'})
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.agent}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#options' do
    pending
  end

  describe '#action' do
    it 'should return the name of the action if it is specified and valid' do
      command_parser = DopCommon::Command.new({
        :plugin => 'mco/rpc',
        :agent  => 'rpcutil',
        :action => 'inventory'
      })
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect(command.action).to eq('inventory')
    end
    it 'will raise an error if action is not defined' do
      command_parser = DopCommon::Command.new({
        :plugin => 'mco/rpc',
        :agent  => 'nonexistingagent'
      })
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.action}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if agent is not valid' do
      command_parser = DopCommon::Command.new({
        :plugin => 'mco/rpc',
        :agent  => 'nonexistingagent',
        :action => 'inventory'
      })
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.action}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if action is not valid' do
      command_parser = DopCommon::Command.new({
        :plugin => 'mco/rpc',
        :agent  => 'rpcutil',
        :action => 'nonexixtingaction'
      })
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.action}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if action is not a String' do
      command_parser = DopCommon::Command.new({
        :plugin => 'mco/rpc',
        :agent  => 'rpcutil',
        :action => 2
      })
      command = Dopi::Command.create_plugin_instance(command_parser.plugin, @node, command_parser)
      expect{command.action}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#arguments' do
    pending
  end

  describe '#run' do
    pending
  end

end
