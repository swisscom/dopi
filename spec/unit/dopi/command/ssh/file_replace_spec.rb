require 'spec_helper'

describe Dopi::Command::Ssh::FileReplace do

  describe '#replacement' do
    it 'should return the replacement value if specified' do
      command = create_command({:plugin => 'ssh/file_replace', :replacement => 'foo'})
      expect(command.replacement).to eq('foo')
    end
    it 'will raise and error if replacement is not specified' do
      command = create_command({:plugin => 'ssh/file_replace'})
      expect{command.replacement}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if replacement is not a String' do
      command = create_command({:plugin => 'ssh/file_replace', :replacement => 2})
      expect{command.replacement}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#global' do
    it 'should return true if nothing is specified' do
      command = create_command({:plugin => 'ssh/file_replace'})
      expect(command.global).to be true
    end
    it 'should return the correct value if specified' do
      command = create_command({:plugin => 'ssh/file_replace', :global => false})
      expect(command.global).to be false
    end
    it 'will raise and error if global is not a boolean' do
      command = create_command({:plugin => 'ssh/file_replace', :global => 2})
      expect{command.global}.to raise_error Dopi::CommandParsingError
    end
  end

end
