require 'spec_helper'

describe Dopi::Step do

  before :all do
    Dopi.log.level = ::Logger::ERROR
  end

  before :each do
    command_hash = {
      'plugin' => 'custom',
      'exec'   => 'echo',
      'arguments' => {
        'Hello World' => nil
      }
    }
    @nodes = []
    @nodes << Dopi::Node.new('web01.example.com', {'role' => 'role1'})
    @nodes << Dopi::Node.new('web02.example.com', {'role' => 'role2'})
    @step = Dopi::Step.new('test_step', command_hash, @nodes)
  end

  describe '#new' do
    it 'takes a name, a command_hash, a list of nodes and returns a Dopi::Step object' do
      expect(@step).to be_an_instance_of Dopi::Step
    end

    it 'takes a name, a plugin name, a list of nodes and returns a Dopi::Step object' do
      step = Dopi::Step.new('test_step', 'dummy', @nodes)
      expect(step).to be_an_instance_of Dopi::Step
    end
  end

end
