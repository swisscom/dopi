#
# DOPi Plugin: Wait For Login
#

module Dopi
  class Command
    class Ssh
      class Reboot < Dopi::Command::Ssh::WaitForLogin

        def run
          ssh_command({}, 'shutdown -r now')
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
      end
    end
  end
end
