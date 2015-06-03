require 'spec_helper'

describe Dopi::Step do

  before :each do
    plan_file = 'spec/data/plan/plan_simple.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser, 'fakeid')

    hash = {
      :name      => 'Test step',
      :command   => {
        :plugin    => 'custom',
        :exec      => 'echo',
        :arguments => 'Hello World'
      }
    }
    @step = Dopi::Step.new(DopCommon::Step.new(hash), @plan.nodes)
  end

  describe '#new' do
    it 'takes a name, a command_hash, a list of nodes and returns a Dopi::Step object' do
      expect(@step).to be_an_instance_of Dopi::Step
    end

    it 'takes a name, a plugin name, a list of nodes and returns a Dopi::Step object' do
      step = Dopi::Step.new(DopCommon::Step.new({:name => 'dummy', :command => 'dummy'}), @plan.nodes)
      expect(step).to be_an_instance_of Dopi::Step
    end
  end

  describe '#run' do
    pending
  end

end
