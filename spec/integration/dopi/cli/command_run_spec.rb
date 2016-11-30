require 'spec_helper'

describe 'command_run' do
  fixture_file 'puppet'
  fixture_file 'plans'

  describe 'run exit code' do
    before :each do
      Dopi.add("spec/fixtures/plans/#{plan_name}.yaml")
    end
    after :each do
      Dopi.remove(plan_name, true)
    end

    context 'plan run will be successful' do
      let(:plan_name) { 'hello_world' }
      command 'dopi --verbosity INFO run hello_world'
      its(:exitstatus) { is_expected.to eq 0 }
    end
    context 'plan will fail on command timeout' do
      let(:plan_name) { 'fail_on_timeout' }
      command 'dopi --verbosity INFO run fail_on_timeout', :allow_error => true
      its(:exitstatus) { is_expected.to_not eq 0 }
    end
  end

  describe 'oneshot exit code' do
    context 'plan run will be successful' do
      command "dopi --verbosity INFO oneshot hello_world.yaml"
      its(:exitstatus) { is_expected.to eq 0 }
    end
    context 'plan will fail on command timeout' do
      command "dopi --verbosity INFO oneshot fail_on_timeout.yaml", :allow_error => true
      its(:exitstatus) { is_expected.to_not eq 0 }
    end
  end

end
