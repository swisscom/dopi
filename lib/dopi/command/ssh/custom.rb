#
# SSH custom command
#

module Dopi
  class Command
    class Ssh
      class Custom < Dopi::Command::Custom

        def ssh_command_string
          options = ""
          unless Dopi.configuration.ssh_option_challenge_response_authentication
            options << ' -o ChallengeResponseAuthentication=no'
          end
          unless Dopi.configuration.ssh_option_password_authentication
            options << ' -o PasswordAuthentication=no'
          end
          unless Dopi.configuration.ssh_option_strict_host_key_checking
            options << ' -o StrictHostKeyChecking=no'
          end

          user = Dopi.configuration.ssh_user
          key  = Dopi.configuration.ssh_key
          "ssh -i #{key}#{options} #{user}@#{@node.name}"
        end

        def command_string
          ssh_command_string + ' ' + super
        end

      end
    end
  end
end
