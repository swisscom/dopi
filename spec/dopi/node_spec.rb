require 'spec_helper'

describe Dopi::Node do

  before :all do
    Dopi.log.level = ::Logger::ERROR

    Dopi.configure do |config|
      config.role_variable = 'my_role'
      config.role_default = 'default_role'
      config.use_hiera = true 
      config.hiera_yaml = 'spec/data/hiera/hiera.yaml'
      config.facts_dir = 'spec/data/facts'
    end
  end

  before :each do
    node_parser = DopCommon::Node.new('web01.example.com', {'my_role' => 'config_role'})
    @node = Dopi::Node.new(node_parser)
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
    
end

