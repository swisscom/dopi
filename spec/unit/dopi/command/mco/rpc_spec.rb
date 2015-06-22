require 'spec_helper'
require 'mcollective'

describe Dopi::Command::Mco::Rpc do

  describe '#agent' do
    it 'should return the name of the agent if it is specified' do
      command = create_command({:plugin => 'mco/rpc', :agent => 'rpcutil'})
      expect(command.agent).to eq('rpcutil')
    end
    it 'will raise and error if agent is not specified and valid' do
      command = create_command({:plugin => 'mco/rpc'})
      expect{command.agent}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if agent is not a String' do
      command = create_command({:plugin => 'mco/rpc', :agent => 2})
      expect{command.agent}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if agent does not exists' do
      command = create_command({:plugin => 'mco/rpc', :agent => 'nonexistingagent'})
      expect{command.agent}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#options' do
    it 'should return the merged options hash if the hash is valid' do
      command = create_command({:plugin => 'mco/rpc', :options => {:ttl => 300}})
      expect(command.options[:ttl]).to eq(300)
    end
    it 'should return the default options hash if the hash is not defined' do
      command = create_command({:plugin => 'mco/rpc'})
      expect(command.options).to eq(command.send(:options_defaults))
    end
    it 'will raise and error if options is not a hash' do
      command = create_command({:plugin => 'mco/rpc', :options => 2})
      expect{command.options}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#action' do
    it 'should return the name of the action if it is specified and valid' do
      command = create_command({
        :plugin => 'mco/rpc',
        :agent  => 'rpcutil',
        :action => 'inventory'
      })
      expect(command.action).to eq('inventory')
    end
    it 'will raise an error if action is not defined' do
      command = create_command({
        :plugin => 'mco/rpc',
        :agent  => 'nonexistingagent'
      })
      expect{command.action}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if agent is not valid' do
      command = create_command({
        :plugin => 'mco/rpc',
        :agent  => 'nonexistingagent',
        :action => 'inventory'
      })
      expect{command.action}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if action is not valid' do
      command = create_command({
        :plugin => 'mco/rpc',
        :agent  => 'rpcutil',
        :action => 'nonexixtingaction'
      })
      expect{command.action}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if action is not a String' do
      command = create_command({
        :plugin => 'mco/rpc',
        :agent  => 'rpcutil',
        :action => 2
      })
      expect{command.action}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#arguments' do
    it 'should return the arguments hash if it is specified and valid' do
      command = create_command({
        :plugin    => 'mco/rpc',
        :agent     => 'rpcutil',
        :action    => 'get_fact',
        :arguments => { :fact => 'osfamily' }
      })
      expect(command.arguments).to eq({ :fact => 'osfamily' })
    end
    it 'should return an empty hash if "arguments" is not specified and all arguments are optional' do
      command = create_command({
        :plugin    => 'mco/rpc',
        :agent     => 'rpcutil',
        :action    => 'inventory'
      })
      expect(command.arguments).to eq({})
    end
    it 'will raise an error if "arguments" is not specified and there are required arguments' do
      command = create_command({
        :plugin    => 'mco/rpc',
        :agent     => 'rpcutil',
        :action    => 'get_fact'
      })
      expect{command.arguments}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if an argument key is not valid' do
      command = create_command({
        :plugin    => 'mco/rpc',
        :agent     => 'rpcutil',
        :action    => 'get_fact',
        :arguments => { :foo => 'osfamily' }
      })
      expect{command.arguments}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if an argument value is not valid' do
      command = create_command({
        :plugin    => 'mco/rpc',
        :agent     => 'rpcutil',
        :action    => 'get_fact',
        :arguments => { :fact => 'osfamily&&' }
      })
      expect{command.arguments}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if agent is not valid' do
      command = create_command({
        :plugin => 'mco/rpc',
        :agent  => 'nonexistingagent',
        :action => 'get_fact'
      })
      expect{command.arguments}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if action is not valid' do
      command = create_command({
        :plugin => 'mco/rpc',
        :agent  => 'rpcutil',
        :action => 'nonexistingaction'
      })
      expect{command.arguments}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if arguments is not a Hash' do
      command = create_command({
        :plugin    => 'mco/rpc',
        :agent     => 'rpcutil',
        :action    => 'get_fact',
        :arguments => 'foo'
      })
      expect{command.arguments}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#run' do
    pending
  end

end
