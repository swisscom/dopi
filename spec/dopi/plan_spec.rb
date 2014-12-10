require 'spec_helper'

describe Dopi::Plan do

  before :all do
    Dopi.log.level = ::Logger::ERROR

    Dopi.configure do |config|
      config.role_variable = 'my_role'
    end
  end

  before :each do
    plan_yaml = 'spec/data/plan/plan_simple.yaml'
    @plan = Dopi::Plan.new( File.read( plan_yaml ) )
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

  describe '#run' do
    pending
  end

end

