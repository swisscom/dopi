#
# DOPi Plugin: Wait For Login
#

module Dopi
  class Command
    class Winrm
      class WaitForLogin < Dopi::Command
        include Dopi::Connector::Winrm
        include Dopi::CommandParser::ExitCode

        DEFAULT_INTERVAL = 10

        def validate
          validate_winrm
          validate_exit_code
          log_validation_method(:interval_valid?, CommandParsingError)
        end

        def run
          connected = false
          until connected
            begin connected = check_exit_code(winrm_command('exit')[2])
            rescue Dopi::NodeConnectionError, Dopi::CommandConnectionError
            end
            unless connected
              sleep interval
              raise GracefulExit if signals[:stop]
              log(:info, "Retrying connect to node")
            end
          end
          true
        end

        def interval
          @interval ||= interval_valid? ?
            hash[:interval] : DEFAULT_INTERVAL
        end

        def interval_valid?
          return false if hash[:interval].nil? # is optional
          hash[:interval].class == Fixnum or
            raise CommandParsingError, "Plugin #{name}: the value of 'interval' has to be a number"
        end

      end
    end
  end
end
