require 'spec_helper'
require 'yaml'

describe Dopi::Plan do

  before :all do
    Dopi.configure do |config|
      config.role_variable = 'my_role'
    end
  end

  before :each do
    plan_file = 'spec/data/plan/plan_simple.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser)
  end

  describe '#new' do
    it 'takes a plan yaml file and returns a Dopi::Plan object' do
      expect(@plan).to be_an_instance_of Dopi::Plan
    end
  end

  describe '#nodes' do
    it 'creates 5 nodes' do
      expect(@plan.nodes.length).to be 5
    end
  end

  describe '#steps' do
    it 'creates 2 steps' do
      expect(@plan.steps.length).to be 2
    end
  end

  describe '#reset' do
    pending
  end

  describe '#run' do
    it 'successfuly run some simple steps' do
      expect(@plan.state_ready?).to be true
      @plan.run
      expect(@plan.state_done?).to be true
    end
    it 'skip steps that are already done' do
      expect(@plan.state_ready?).to be true
      @plan.run
      expect(@plan.state_done?).to be true
      @plan.run
      expect(@plan.state_done?).to be true
    end
  end

end

