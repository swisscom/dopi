require 'spec_helper'

describe Dopi::Step do

  before :all do
    Dopi.log.level = ::Logger::ERROR
  end

  before :each do
    hash = {
      :name      => 'Test step',
      :command   => {
        :plugin    => 'custom',
        :exec      => 'echo',
        :arguments => 'Hello World'
      }
    }
    @nodes = []
    @nodes << Dopi::Node.new(DopCommon::Node.new('web01.example.com', {'role' => 'role1'}))
    @nodes << Dopi::Node.new(DopCommon::Node.new('web02.example.com', {'role' => 'role2'}))
    @step = Dopi::Step.new(DopCommon::Step.new(hash), @nodes)
  end

  describe '#new' do
    it 'takes a name, a command_hash, a list of nodes and returns a Dopi::Step object' do
      expect(@step).to be_an_instance_of Dopi::Step
    end

    it 'takes a name, a plugin name, a list of nodes and returns a Dopi::Step object' do
      step = Dopi::Step.new(DopCommon::Step.new({:name => 'dummy', :command => 'dummy'}), @nodes)
      expect(step).to be_an_instance_of Dopi::Step
    end
  end

  describe '#run' do
    pending
  end

end
