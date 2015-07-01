require 'spec_helper'

describe Dopi::Node do

  before :all do
    Dopi.configure do |config|
      config.role_variable = 'my_role'
      config.role_default  = 'default_role'
      config.hiera_yaml    = 'spec/data/hiera/hiera.yaml'
      config.facts_dir     = 'spec/data/facts'
    end
  end

  before :each do
    plan_file = 'spec/data/plan/plan_simple.yaml'
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    @plan = Dopi::Plan.new(plan_parser)
    @node = @plan.nodes.find {|node| node.name == 'web01.example.com'}
  end

  describe '#new' do
    it 'takes a fqdn and a node config hash and returns a Dopi::Node object' do
      expect(@node).to be_an_instance_of Dopi::Node
    end
  end
 
  describe '#role' do
    it 'should return the role from hiera' do
      expect(@node.role).to eq 'hiera_role'
    end
  end

  describe '#ssh_root_pass' do
    it 'should return the default root password' do
      Dopi.configuration.use_hiera = false
      expect(@node.ssh_root_pass).to eq 'pass_from_plan'
    end
    it 'should return the root password from hiera' do
      Dopi.configuration.use_hiera = true
      expect(@node.ssh_root_pass).to eq 'pass_from_hiera'
    end
  end

end

