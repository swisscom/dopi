require 'spec_helper'

describe Dopi::Command::Ssh::FileDeploy do

  describe '#file' do
    it 'should return the file path if specified correctly' do
      command = create_command({:plugin => 'ssh/file_deploy', :file => '/tmp/foo'})
      expect(command.file).to eq('/tmp/foo')
    end
    it 'will raise an error if the file path is not pecified' do
      command = create_command({:plugin => 'ssh/file_deploy'})
      expect{command.file}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise an error if file path is not a String' do
      command = create_command({:plugin => 'ssh/file_deploy', :file => 2})
      expect{command.file}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#content' do
    it 'should return an error if nothing is specified' do
      command = create_command({:plugin => 'ssh/file_deploy'})
      expect{command.content}.to raise_error Dopi::CommandParsingError
    end
    it 'should return the content if specified correctly as a string' do
      command = create_command({:plugin => 'ssh/file_deploy', :content => 'hello world'})
      expect(command.content).to eq('hello world')
    end
    it 'should return the content if specified correctly as a file' do
      file = Tempfile.new('secret_file', ENV['HOME'])
      file.write('hello world')
      file.close
      command = create_command({:plugin => 'ssh/file_deploy', :content => {'file' => file.path} })
      expect(command.content).to eq('hello world')
      file.delete
    end
    it 'will raise an error if content is not a string' do
      command = create_command({:plugin => 'ssh/file_deploy', :content => 2})
    end
  end

end
