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
    @node = Dopi::Node.new('web01.example.com', {'my_role' => 'config_role'})
  end

  describe '#new' do
    it 'takes a fqdn and a node config hash and returns a Dopi::Node object' do
      expect(@node).to be_an_instance_of Dopi::Node
    end
  end

  describe '#hostname' do
    it 'schould return the correct hostname' do
      expect(@node.hostname).to eq 'web01'
    end
  end

  describe '#domain' do
    it 'should return the correct domain' do
      expect(@node.domain).to eq 'example.com'
    end
  end

  describe '#basic_scope' do
    it 'should return a hash which contains some basic scope' do
      expect(@node.basic_scope).to be_an_instance_of Hash
      expect(@node.basic_scope['::fqdn']).to eq 'web01.example.com'
      expect(@node.basic_scope['::clientcert']).to eq 'web01.example.com'
      expect(@node.basic_scope['::hostname']).to eq 'web01'
      expect(@node.basic_scope['::domain']).to eq 'example.com'
    end
  end

  describe '#facts' do
    it 'should return a hash which contains facts' do
      expect(@node.facts).to be_an_instance_of Hash
      expect(@node.facts['fqdn']).to eq 'web01.example.com'
      expect(@node.facts['clientcert']).to eq 'web01.example.com'
      expect(@node.facts['hostname']).to eq 'web01'
      expect(@node.facts['domain']).to eq 'example.com'
    end
  end

  describe '#ensure_global_namespace' do
    it 'should return a variable in the global namespace' do
      expect(@node.ensure_global_namespace('myvar')).to eq '::myvar'
      expect(@node.ensure_global_namespace('::myvar')).to eq '::myvar'
    end
  end

  describe '#scope' do
    it 'should return a hash which contains the merged scope' do
      expect(@node.scope).to be_an_instance_of Hash
      expect(@node.scope['::fqdn']).to eq 'web01.example.com'
      expect(@node.scope['::clientcert']).to eq 'web01.example.com'
      expect(@node.scope['::hostname']).to eq 'web01'
      expect(@node.scope['::domain']).to eq 'example.com'
    end
  end

  describe '#role_default' do
    it 'should return the default role' do
      expect(@node.role_default).to eq 'default_role'
    end
  end

  describe '#role_from_config' do
    it 'should return the role from the config' do
      expect(@node.role_from_config).to eq 'config_role'
    end
  end
  
  describe '#role_from_hiera' do
    it 'should return the role from hiera' do
      expect(@node.role_from_hiera).to eq 'hiera_role'
    end
  end
 
   describe '#role' do
    it 'should return the role from hiera' do
      expect(@node.role).to eq 'hiera_role'
    end
  end
    
end

