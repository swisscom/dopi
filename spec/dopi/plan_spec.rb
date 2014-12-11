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

  describe '#configuration_hash' do
    it 'extracts the configuration hash out of the plan hash' do
      expect(@plan.configuration_hash).to be_an_instance_of Hash
      expect(@plan.configuration_hash['nodes']).to be_an_instance_of Hash
    end
  end

  describe '#nodes_configuration_hash' do
    it 'extracts the nodes configuration hash out of the configuration hash' do
      expect(@plan.nodes_configuration_hash).to be_an_instance_of Hash
      expect(@plan.nodes_configuration_hash['web01.example.com']).to be_an_instance_of Hash
    end
  end

  describe '#steps_array' do
    it 'extracts the steps array out of the plan hash' do
      expect(@plan.steps_array).to be_an_instance_of Array
      expect(@plan.steps_array[0]).to be_an_instance_of Hash
      expect(@plan.steps_array[1]).to be_an_instance_of Hash
    end
  end

  describe '#nodes_by_fqdns' do
    it 'takes an array of fqdns and returns an array of nodes' do
      fqdns = ['web01.example.com', 'web02.example.com']
      nodes = @plan.nodes_by_fqdns(fqdns)
      expect(nodes.length).to be 2
      nodes.each {|node| expect(fqdns).to include node.fqdn}
    end
  end

  describe '# nodes_by_roles' do
    it 'takes an array of fqdns and returns an array of nodes' do
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

