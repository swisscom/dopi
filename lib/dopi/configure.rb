#
# Configration for DOPi
#
# Configure the module in a block:
#
#   Dopi.configure do |config|
#     config.use_hiera = true
#   end
#
# Configure the module via configfile:
#
#   Dopi.load_configfile('/etc/my/dopi/config.yaml')
#
# Configure the module via a hash of settings
#
#   Dopi.load_confighash({ 'use_hiera' => true })
#
require 'yaml'

module Dopi

  class << self
    attr_accessor :configuration
  end

  def self.load_configfile( configfile = '/etc/dop/dopi.conf' )
    if File.exists?(configfile)
      confighash = YAML.load_file( configfile )
      self.load_confighash( confighash )
    else
      ## TODO: Throw proper exception classes
      raise "Configfile #{configfile} does not exist"
    end
  end

  def self.load_confighash( confighash )
    self.configuration ||= Configuration.new
    confighash.each do |key, value|
      variable_name = '@' + key
      if configuration.instance_variable_defined?( variable_name )
        configuration.instance_variable_set( variable_name , value )
      else
        ## TODO: Throw proper exception classes
        raise "Unknown config option: #{key}"
      end
    end
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :use_hiera, :hiera_yaml, :facts_dir
    attr_accessor :role_variable, :role_default

    def initialize
      # Hiera defaults
      @use_hiera  = false
      @hiera_yaml = '/etc/hiera.yaml'
      @facts_dir  = '/var/lib/puppet/yaml/facts/'

      # Role defaults
      @role_variable = 'role'
      @role_default  = nil
    end
 
  end

end
