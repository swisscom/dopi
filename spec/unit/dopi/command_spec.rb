require 'spec_helper'

describe Dopi::Command do

  describe '#create_plugin_instance' do
    it 'takes a plugin name, a node and a command parser and returns a command plugin' do
      command = create_command('dummy')
      expect(command).to be_a_kind_of Dopi::Command
      command = create_command({:plugin => 'dummy'})
      expect(command).to be_a_kind_of Dopi::Command
    end
  end

end
