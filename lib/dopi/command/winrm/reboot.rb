#
# DOPi Plugin: Wait For Login
#

module Dopi
  class Command
    class Winrm
      class Reboot < Dopi::Command::Winrm::WaitForLogin

        def run
          winrm_powershell_command('shutdown /r /f /t 0')
          connected = true
          while connected
            begin
              @node.reset_address(port)
              @node.address(port)
            rescue Dopi::NodeConnectionError
              connected = false
            end
            if connected
              sleep 1
              raise GracefulExit if signals[:stop]
              log(:info, "Still able to login, waiting for shutdown")
            end
          end
          log(:info, "Node is down, starting to check for login")
          super
        end

      end
    end
  end
end
