#
# SSH custom command
#

module Dopi
  class Command
    class Ssh
      class Custom < Dopi::Command::Custom

        def sshpass_bin
          @sshpass_bin ||= ENV['PATH'].split(':').map{|p| File.join(p, 'sshpass')}.find do |f|
            File.exists?(f) && File.executable?(f)
          end
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
            options << " -i #{Dopi.configuration.ssh_key}"
            if Dopi.configuration.ssh_pass_auth
              Dopi.log.warn('ssh password login disabled because sshpass is not installed') unless sshpass_bin
              Dopi.log.warn("ssh password login disabled because no root password found for node #{@node.name}") unless sshpass_env
            end
          end
          unless Dopi.configuration.ssh_check_host_key
            options << ' -o StrictHostKeyChecking=no'
          end
          options << ' -q' if quiet
          user = Dopi.configuration.ssh_user
          "#{sshpass_cmd}ssh #{options} #{user}@#{@node.name}"
        end

        def escape_string(string)
          string.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
        end

        def env_string
          escape_string(env.collect{|k,v| "#{k}=#{v}"}.join(' '))
        end

        def command_string
          ssh_command_string + " \"#{env_string} #{escape_string(super)}\""
        end

        def env
          @ssh_env ||= super.merge(sshpass_env || {}) 
        end

        def validate
          super
          log_validation_method('quiet_valid?', CommandParsingError)
        end

        def quiet
          @quiet || quiet_valid? ? hash[:quiet] : true
        end

        def quiet_valid?
          return false unless hash.kind_of?(Hash)
          return false if hash[:quiet].nil? # is optional
          hash[:quiet].kind_of?(TrueClass) or hash[:quiet].kind_of?(FalseClass) or
            raise ComandParsingError, "Plugin #{name}: The value for quiet must be boolean"
        end

      end
    end
  end
end
