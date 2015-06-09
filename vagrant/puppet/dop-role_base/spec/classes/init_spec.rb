require 'spec_helper'
describe 'role_base' do

  context 'with defaults for all parameters' do
    it { should contain_class('role_base') }
  end
end
