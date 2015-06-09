require 'spec_helper'
describe 'role_puppetmaster' do

  context 'with defaults for all parameters' do
    it { should contain_class('role_puppetmaster') }
  end
end
