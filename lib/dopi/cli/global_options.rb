#
# DOPi CLI gloable options
#

module Dopi
  module Cli

    def self.global_options(base)
      base.class_eval do
        desc 'Use Hiera to get the role for the nodes'
        default_value DopCommon.config.use_hiera
        switch [:use_hiera, :h]

        desc 'Specify the hiera configuration file'
        default_value DopCommon.config.hiera_yaml
        arg_name 'YAML'
        flag [:hiera_yaml]

        desc 'Try to load the scope for the nodes from existing facts'
        default_value DopCommon.config.load_facts
        switch [:load_facts]

        desc 'Specify the directory where dopi can find facts'
        default_value DopCommon.config.facts_dir
        arg_name 'DIR'
        flag [:facts_dir]

        desc 'Set the name of the variable DOPi should use as the roles variable'
        default_value DopCommon.config.role_variable
        arg_name 'VARIABLE_NAME'
        flag [:role_variable]

        desc 'Set the default value for the node role'
        default_value DopCommon.config.role_default
        arg_name 'ROLE'
        flag [:role_default]

        desc 'Set the MCollective client configuration.'
        default_value DopCommon.config.mco_config
        arg_name 'FILE'
        flag [:mco_config]

        desc 'Use the DOPi logger to capture MCollective logs (this is enabled by default)'
        default_value DopCommon.config.mco_dopi_logger
        switch [:mco_dopi_logger]

        desc 'Time until a connection check is marked as failure'
        default_value DopCommon.config.connection_check_timeout
        arg_name 'SECONDS'
        flag [:connection_check_timeout]
      end
    end

  end
end
