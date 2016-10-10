require 'spec_helper'

describe 'global cli options' do
  fixture_file 'puppet'
  fixture_file 'plans'

  describe 'connection_check_timeout' do
    pending
  end

  describe 'facts_dir' do
    pending # This option should be removed
  end

  describe 'hiera_yaml' do
    context 'Invalid hiera.yaml' do
      command 'dopi --hiera_yaml ./nothiera.yaml oneshot test_role_variable.yaml', :allow_error => true
      its(:stdout) {is_expected.to include 'hiera.yaml not found! Using empty config'}
    end
    context 'Valid hiera.yaml' do
      command 'dopi --hiera_yaml ./hiera.yaml oneshot test_role_variable.yaml', :allow_error => true
      its(:stdout) {is_expected.not_to include 'hiera.yaml not found! Using empty config'}
    end
  end

  describe 'load_facts' do
    pending # This option should be removed
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
    context 'INFO' do
      it 'should not contain debug output in the log file' do
        command "dopi --log_dir ./mylog --log_level INFO oneshot hello_world.yaml"
        log_file = File.join(temp_path, 'mylog', 'dopi.log')
        expect(File.read(log_file)).not_to include
          'Executing echo "hello world"'
      end
    end
    context 'DEBUG' do
      it 'should contain debug output in the log file' do
        command "dopi --log_dir ./mylog --log_level DEBUG oneshot hello_world.yaml"
        log_file = File.join(temp_path, 'mylog', 'dopi.log')
        expect(File.read(log_file)).to include
          'Executing echo "hello world"'
      end
    end
  end

  describe 'mco_config' do
    pending
  end

  describe 'mco_dopi_logger' do
    pending
  end

  describe 'plan_store_dir' do
    before :each do
      command "dopi --plan_store_dir ./plan_store add hello_world.yaml"
    end
    it 'should create the directory' do
      expect(Dir.entries(temp_path)).to include 'plan_store'
    end
    it 'should add the plan to the plan_store' do
      stored_plan = File.join(temp_path, 'plan_store', 'hello_world')
      expect(File.exists?(stored_plan)).to be true
    end
  end

  describe 'role_default' do
    context 'role_default is not set' do
      command 'dopi oneshot test_role_variable.yaml', :allow_error => true
      its(:stdout) {is_expected.to include 'No role found for linux01.example.com'}
    end
    context 'role_default is set' do
      command 'dopi --role_default testnode oneshot test_role_variable.yaml'
      its(:stdout) {is_expected.to include "Step 'write hello world' successfully finished."}
    end
  end

  describe 'role_variable' do
    context 'role_variable is not set' do
      command 'dopi --hiera_yaml hiera.yaml oneshot test_role_variable.yaml', :allow_error => true
      its(:stdout) {is_expected.to include 'No role found for linux01.example.com'}
    end
    context 'role_default is set' do
      command 'dopi --hiera_yaml hiera.yaml --role_variable test_role oneshot test_role_variable.yaml'
      its(:stdout) {is_expected.to include "Step 'write hello world' successfully finished."}
    end
  end

  describe 'use_hiera' do
    context 'default behaviour' do
      command 'dopi --hiera_yaml ./nothiera.yaml oneshot test_role_variable.yaml', :allow_error => true
      its(:stdout) {is_expected.to include 'hiera.yaml not found! Using empty config'}
    end
    context 'Disable hiera' do
      command 'dopi --no-use_hiera oneshot test_role_variable.yaml', :allow_error => true
      its(:stdout) {is_expected.not_to include 'hiera.yaml not found! Using empty config'}
    end
  end

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

end
