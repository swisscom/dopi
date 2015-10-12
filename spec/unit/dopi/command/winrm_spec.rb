require 'spec_helper'

describe Dopi::Command::Winrm do

  describe '#port' do
    it 'should return the default port if not specified' do
      command = create_command({:plugin => 'winrm'})
      expect(command.port).to eq(5985)
    end
    it 'should return the port if it is specified' do
      command = create_command({:plugin => 'winrm', :port => 42})
      expect(command.port).to eq(42)
    end
    it 'will raise and error if the port is not specified as a number' do
      command = create_command({:plugin => 'winrm', :port => '42'})
      expect{command.port}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if the port is smaller than 1' do
      command = create_command({:plugin => 'winrm', :port => 0})
      expect{command.port}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if the port is bigger than 65535' do
      command = create_command({:plugin => 'winrm', :port => 10000000})
      expect{command.port}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#ssl' do
    it 'should return false if specified as false' do
      command = create_command({:plugin => 'winrm', :ssl => false})
      expect(command.ssl).to be false
    end
    it 'should return true if not specified' do
      command = create_command({:plugin => 'winrm'})
      expect(command.ssl).to be true
    end
    it 'will raise and error if specified wrong' do
      command = create_command({:plugin => 'winrm', :ssl => 'foo'})
      expect{command.ssl}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#ca_trust_path' do
    it 'should return the path if specified' do
      command = create_command({:plugin => 'winrm', :ca_trust_path => 'spec/unit'})
      expect(command.ca_trust_path).to eq('spec/unit')
    end
    it 'should return nil if not specified' do
      command = create_command({:plugin => 'winrm'})
      expect(command.ca_trust_path).to be nil
    end
    it 'will raise and error if specified wrong' do
      command = create_command({:plugin => 'winrm', :ca_trust_path => 'foo'})
      expect{command.ca_trust_path}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#disable_sspi' do
    it 'should return false if specified as false' do
      command = create_command({:plugin => 'winrm', :disable_sspi => true})
      expect(command.disable_sspi).to be true
    end
    it 'should return true if not specified' do
      command = create_command({:plugin => 'winrm'})
      expect(command.disable_sspi).to be nil
    end
    it 'will raise and error if specified wrong' do
      command = create_command({:plugin => 'winrm', :disable_sspi => 'foo'})
      expect{command.disable_sspi}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#basic_auth_only' do
    it 'should return false if specified as false' do
      command = create_command({:plugin => 'winrm', :basic_auth_only => true})
      expect(command.basic_auth_only).to be true
    end
    it 'should return true if not specified' do
      command = create_command({:plugin => 'winrm'})
      expect(command.basic_auth_only).to be nil
    end
    it 'will raise and error if specified wrong' do
      command = create_command({:plugin => 'winrm', :basic_auth_only => 'foo'})
      expect{command.basic_auth_only}.to raise_error Dopi::CommandParsingError
    end
  end



end
