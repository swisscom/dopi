#
# Configration for DOPi
#
# Configure the module in a block:
#
#   Dopi.configure do |config|
#     config.use_hiera = true
#   end
#

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
    attr_accessor :ssh_user, :ssh_key,
                  :ssh_pass_auth, :ssh_check_host_key

    def initialize
      # Defaults
      @trace          = false
      @config_file    = '/etc/dop/dopi.conf'
      @plan_cache_dir = '/var/lib/dop/plans/'

      # Hiera defaults
      @use_hiera  = true
      @hiera_yaml = '/etc/puppet/hiera.yaml'
      @load_facts = false
      @facts_dir  = '/var/lib/puppet/yaml/facts/'

      # Role defaults
      @role_variable = 'role'
      @role_default  = nil

      # SSH defaults
      @ssh_user = 'root'
      @ssh_key  = File.join(ENV['HOME'], '.ssh/id_dsa')
      @ssh_pass_auth = false
      @ssh_check_host_key = false
    end
 
  end

end
