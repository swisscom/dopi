#
# Configration for DOPi
#
# Configure the module in a block:
#
#   Dopi.configure do |config|
#     config.use_hiera = true
#   end
#
require 'etc'

module Dopi

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield configuration
  end

  def self.configure=(options_hash)
    options_hash.each do |key, value|
      variable_name = '@' + key.to_s
      if configuration.instance_variable_defined?( variable_name )
        configuration.instance_variable_set( variable_name , value )
      end
    end
  end

  class Configuration
    attr_accessor :trace, :config_file, :plan_cache_dir
    attr_accessor :use_hiera, :hiera_yaml, :load_facts, :facts_dir
    attr_accessor :role_variable, :role_default
    attr_accessor :connection_check_timeout
    attr_accessor :mco_config, :mco_dopi_logger
    attr_accessor :log_dir, :log_level

    def initialize
      user = Etc.getpwuid(Process.uid)
      is_root = user.name == 'root'
      dopi_home = File.join(user.dir, '.dop')

      # Defaults
      @trace          = false
      @config_file    = is_root ?
        '/etc/dop/dopi.conf' :
        File.join(dopi_home, 'dopi.conf')
      @plan_cache_dir = is_root ?
        '/var/lib/dop/plans/' :
        File.join(dopi_home, 'cache')

      # Hiera defaults
      @use_hiera  = true
      @hiera_yaml = is_root ?
        '/etc/puppet/hiera.yaml' :
        File.join(user.dir, '.puppet', 'hiera.yaml')
      @load_facts = false
      @facts_dir  = is_root ?
        '/var/lib/puppet/yaml/facts/' :
        File.join(user.dir, '.puppet', 'var', 'yaml', 'facts')

      # Connection
      @connection_check_timeout = 5

      # Role defaults
      @role_variable = 'role'
      @role_default  = nil

      # MCO defaults
      @mco_config = is_root ?
        '/etc/mcollective/client.cfg':
        File.join(user.dir, '.mcollective')
      @mco_dopi_logger = true

      # logging
      @log_dir   = is_root ?
        '/var/log/dop/dopi' :
        File.join(dopi_home, 'log')
      @log_level = 'DEBUG'
    end

  end

end
