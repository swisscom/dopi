#
# DOPi Plugin: Wait For Login
#
# This DOPi Plugin will try to connect to the node until a successful login
# is possible or until a timeout is reached.
#
# Plugin Settings:
#
# plugin_timeout
# Amount of seconds the plugin should try to login to the node.
# default: 300
#
# connect_timeout
# Amount of seconds to wait while connecting until giving up.
# default: 0
#
# interval
# Amount of seconds to wait between login attempts.
# default: 10
#

module Dopi
  class Command
    class Ssh
      class WaitForLogin < Dopi::Command::Ssh::Custom

        DEFAULT_CONNECTION_TIMEOUT = 0
        DEFAULT_INTERVAL = 10

        def ssh_command_string
          super + " -o ConnectTimeout=#{connection_timeout} -q "
        end

        def exec
          'exit'
        end

        def run
          until check_exit_code(run_command[2])
            sleep interval
          end
          true
        end

        def connection_timeout
          @connection_timeout ||= connection_timeout_valid? ?
            hash['connection_timeout'] : DEFAULT_CONNECTION_TIMEOUT
        end

        def connection_timeout_valid?
          return false if hash['connection_timeout'].nil? # is optional
          hash['connection_timeout'].class == Fixnum or
            raise CommandParsingError, "Plugin #{name}: the value of 'connection_timeout' has to be a number"
        end

        def interval
          @interval ||= interval_valid? ?
            hash['interval'] : DEFAULT_INTERVAL
        end

        def interval_valid?
          return false if hash['interval'].nil? # is optional
          hash['interval'].class == Fixnum or
            raise CommandParsingError, "Plugin #{name}: the value of 'interval' has to be a number"
        end

      end
    end
  end
end
