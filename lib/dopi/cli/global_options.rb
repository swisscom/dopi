#
# DOPi CLI gloable options
#

module Dopi
  module Cli

    def self.global_options(base)
      base.class_eval do
        desc 'Show stacktrace on crash'
        default_value Dopi.configuration.trace
        switch [:trace, :t]

        desc 'Specify the directory where DOPi will cache data about the plans'
        default_value Dopi.configuration.plan_cache_dir
        arg_name 'DIR'
        flag [:plan_cache_dir, :p]

        desc 'Use Hiera to get the role for the nodes'
        default_value Dopi.configuration.use_hiera
        switch [:use_hiera, :h]

        desc 'Specify the hiera configuration file'
        default_value Dopi.configuration.hiera_yaml
        arg_name 'YAML'
        flag [:hiera_yaml]

        desc 'Try to load the scope for the nodes from existing facts'
        default_value Dopi.configuration.load_facts
        switch [:load_facts]

        desc 'Specify the directory where dopi can find facts'
        default_value Dopi.configuration.facts_dir
        arg_name 'DIR'
        flag [:facts_dir]

        desc 'Set the name of the variable DOPi should use as the roles variable'
        default_value Dopi.configuration.role_variable
        arg_name 'VARIABLE_NAME'
        flag [:role_variable]

        desc 'Set the default value for the node role'
        default_value Dopi.configuration.role_default
        arg_name 'ROLE'
        flag [:role_default]

        desc 'Set the default ssh user (DEPRECATED: Use the credentials hash method)'
        default_value Dopi.configuration.ssh_user
        arg_name 'USERNAME'
        flag [:ssh_user]

        desc 'Set the default ssh key (DEPRECATED: Use the credentials hash method)'
        default_value Dopi.configuration.ssh_key
        arg_name 'SSHKEY'
        flag [:ssh_key]

        desc 'Allow ssh logins with password (DEPRECATED: Use the credentials hash method)'
        default_value Dopi.configuration.ssh_pass_auth
        switch [:ssh_pass_auth]

        desc 'Force ssh to check the host keys (this is disabled by default because we usually deal with new hosts)'
        default_value Dopi.configuration.ssh_check_host_key
        switch [:ssh_check_host_key]

        desc 'Set the MCollective client configuration.'
        default_value Dopi.configuration.mco_config
        arg_name 'FILE'
        flag [:mco_config]

        desc 'Use the DOPi logger to capture MCollective logs (this is enabled by default)'
        default_value Dopi.configuration.mco_dopi_logger
        switch [:mco_dopi_logger]

        desc 'Time until a connection check is marked as failure'
        default_value Dopi.configuration.connection_check_timeout
        arg_name 'SECONDS'
        flag [:connection_check_timeout]

        desc 'Directory for the log files'
        default_value Dopi.configuration.log_dir
        arg_name 'LOGDIR'
        flag [:log_dir]

        desc 'Log level for the logfiles'
        default_value Dopi.configuration.log_level
        arg_name 'LOGLEVEL'
        flag [:log_level, :l]
      end
    end

  end
end
