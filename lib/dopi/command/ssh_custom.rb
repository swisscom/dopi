#
# SSH custom command
#

module Dopi
  class Command

    class SshCustom < Dopi::Command::Custom

      def ssh_command_string
        user = Dopi.configuration.ssh_user
        key  = Dopi.configuration.ssh_key
        "ssh -i #{key} #{user}@#{node.fqdn}"
      end

      def command_string
        ssh_command_string + ' ' + super
      end

    end

  end
end
