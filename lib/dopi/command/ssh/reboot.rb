#
# DOPi Plugin: Reboot a node
#

module Dopi
  class Command
    class Ssh
      class Reboot < Dopi::Command::Ssh::WaitForLogin

        def validate
          super
          log_validation_method(:reboot_cmd_valid?, CommandParsingError)
        end

        def run
          ssh_command({}, reboot_cmd)
          connected = true
          @connection_timeout = 1
          while connected
            begin connected = check_exit_code(ssh_command({}, 'exit')[2])
            rescue Dopi::NodeConnectionError, Dopi::CommandConnectionError
              connected = false
            end
            if connected
              sleep 1
              raise GracefulExit if signals[:stop]
              log(:info, "Still able to login, waiting for shutdown")
            end
          end
          log(:info, "Node is down, starting to check for login")
          @connection_timeout = nil
          super
        end

        def reboot_cmd
          @reboot_cmd ||= reboot_cmd_valid? ? hash[:reboot_cmd] : 'shutdown -r now')
        end
        private
        def reboot_cmd_valid?
          return false if hash[:reboot_cmd].nil? # is optional
          hash[:reboot_cmd].class == String or
            raise CommandParsingError, "Plugin #{name}: the value of 'reboot_cmd' has to be a string"
        end

      end
    end
  end
end
