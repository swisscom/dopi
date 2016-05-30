require 'spec_helper'

describe Dopi::Command do

  describe '#exec' do
    it 'should return the exec value if specified' do
      command = create_command({:plugin => 'custom', :exec => 'echo'})
      expect(command.exec).to eq('echo')
    end
    it 'will raise and error if exec is not specified' do
      command = create_command({:plugin => 'custom'})
      expect{command.exec}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if exec is not a String' do
      command = create_command({:plugin => 'custom', :exec => 2})
      expect{command.exec}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#env' do
    it 'should return the defaults hash if nothing is specified' do
      command = create_command({:plugin => 'custom'})
      expect(command.env).to eq({'DOP_NODE_FQDN' => 'test.example.com'})
    end
    it 'should return the specified hash merged with the defaults' do
      command = create_command({:plugin => 'custom', :env => {'MYVAR' => 'MYVALUE'}})
      expect(command.env).to eq({'DOP_NODE_FQDN' => 'test.example.com', 'MYVAR' => 'MYVALUE'})
    end
    it 'will raise and error if env is not a hash' do
      command = create_command({:plugin => 'custom', :env => 2})
      expect{command.env}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#arguments' do
    it 'should return an empty hash if nothing is specified' do
      command = create_command({:plugin => 'custom'})
      expect(command.arguments).to eq("")
    end
    it 'should return a correct string if arguments are specified as a String' do
      command = create_command({:plugin => 'custom', :arguments => "my custom arguments"})
      expect(command.arguments).to eq("my custom arguments")
    end
    it 'should return a correct string if arguments are specified as an Array' do
      command = create_command({:plugin => 'custom', :arguments => ['my', 'custom', 'arguments']})
      expect(command.arguments).to eq("my custom arguments")
    end
    it 'should return a correct string if arguments are specified as a Hash' do
      command = create_command({:plugin => 'custom', :arguments => {'my' =>  'custom', 'arguments' => ''}})
      expect(command.arguments).to eq("my custom arguments ")
    end
    it 'will raise and error if arguments is not a String, Array or Hash' do
      command = create_command({:plugin => 'custom', :arguments => 2})
      expect{command.arguments}.to raise_error Dopi::CommandParsingError
    end
  end

end
