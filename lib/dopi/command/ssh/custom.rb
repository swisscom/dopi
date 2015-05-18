#
# SSH custom command
#
require 'mkmf'

module Dopi
  class Command
    class Ssh
      class Custom < Dopi::Command::Custom

        def sshpass_bin
          @sshpass_bin ||= find_executable('sshpass')
        end

        def sshpass_env
          @sshpass_env ||= @node.ssh_root_pass ? {'SSHPASS' => @node.ssh_root_pass} : nil
        end

        def sshpass_cmd
          @sshpass_cmd ||= (sshpass_bin && sshpass_env) ? sshpass_bin + ' -e ' : ""
        end

        def ssh_command_string
          options = ""
          unless Dopi.configuration.ssh_pass_auth && sshpass_bin && sshpass_env
            options << ' -o ChallengeResponseAuthentication=no'
            options << ' -o PasswordAuthentication=no'
            if Dopi.configuration.ssh_pass_auth
              Dopi.log.warn('ssh password login disabled because sshpass is not installed') unless sshpass_bin
              Dopi.log.warn("ssh password login disabled because no root password found for node #{@node.name}") unless sshpass_env
            end
          end
          unless Dopi.configuration.ssh_check_host_key
            options << ' -o StrictHostKeyChecking=no'
          end
          user = Dopi.configuration.ssh_user
          key  = Dopi.configuration.ssh_key
          "#{sshpass_cmd}ssh -i #{key}#{options} #{user}@#{@node.name}"
        end

        def command_string
          ssh_command_string + ' ' + super
        end

        def env
          @ssh_env ||= super.merge(sshpass_env || {}) 
        end

      end
    end
  end
end
