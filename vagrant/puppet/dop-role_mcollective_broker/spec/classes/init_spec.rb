require 'spec_helper'
describe 'role_mcollective_broker' do

  context 'with defaults for all parameters' do
    it { should contain_class('role_mcollective_broker') }
  end
end
