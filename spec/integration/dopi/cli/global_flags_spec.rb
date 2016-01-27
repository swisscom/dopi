require 'spec_helper'

describe 'global cli flag' do
  fixture_file 'plans'

  describe '--verbosity' do
    context 'INFO' do
      command "dopi --verbosity INFO oneshot hello_world.yaml"
      its(:stdout) {is_expected.not_to include 'Executing echo "hello world"'}
    end
    context 'DEBUG' do
      command "dopi --verbosity DEBUG oneshot hello_world.yaml"
      its(:stdout) {is_expected.to include 'Executing echo "hello world"'}
    end
  end

  describe 'connection_check_timeout' do
    pending
  end

  describe '--log_dir' do
    before :each do
      command "dopi --log_dir ./mylog oneshot hello_world.yaml"
    end
    it 'should create the directory' do
      expect(Dir.entries(temp_path)).to include 'mylog'
    end
    it 'should write to the log file in the directory' do
      log_file = File.join(temp_path, 'mylog', 'dopi.log')
      expect(File.read(log_file)).to include
        "Step 'write hello world' successfully finished."
    end
  end

  describe 'log_level' do
    pending
  end

  describe 'mco_config' do
    pending
  end

  describe 'plan_cache_dir' do
    pending
  end

  describe 'role_default' do
    pending
  end

  describe 'role_variable' do
    pending
  end

  # OLD STUFF
  # The following flags are deprecated or not
  # actually used

  describe 'ssh_key' do
    pending
  end

  describe 'ssh_user' do
    pending
  end

  describe 'facts_dir' do
    pending
  end

end
