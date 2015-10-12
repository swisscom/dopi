require 'spec_helper'
require 'yaml'

describe Dopi::Plan do

  before :each do
    plan_file = 'spec/integration/dopi/plans/ssh_parallel.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser)
  end

  describe '#new' do
    it 'should create a plan object' do
      expect(@plan).to be_a Dopi::Plan
    end
  end

  describe '#nodes' do
    it 'creates 3 nodes' do
     expect(@plan.nodes.length).to be 3
    end
  end

  describe '#step_sets' do
    it 'creates 1 step set' do
      expect(@plan.step_sets.length).to be 1
    end
  end

end

