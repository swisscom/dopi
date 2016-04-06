require 'spec_helper'

describe Dopi::Command::Ssh do

  describe '#quiet' do
    pending
  end

  describe '#port' do
    it 'should return the default port if nothing is specified' do
      command = create_command({:plugin => 'ssh/custom'})
      expect(command.port).to eq('22')
    end
    it 'should return the correct port if specified correctly' do
      command = create_command({:plugin => 'ssh/custom', :port => 42})
      expect(command.port).to eq('42')
    end
    it 'will raise an error if port is not a number' do
      command = create_command({:plugin => 'ssh/custom', :port => "2"})
      expect{command.port}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if port is not in the valid range' do
      command = create_command({:plugin => 'ssh/custom', :port => -1})
      expect{command.port}.to raise_error Dopi::CommandParsingError
      command = create_command({:plugin => 'ssh/custom', :port => 70000})
      expect{command.port}.to raise_error Dopi::CommandParsingError
    end
  end

end
