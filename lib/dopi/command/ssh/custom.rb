#
# SSH custom command
#

module Dopi
  class Command
    class Ssh
      class Custom < Dopi::Command::Custom
        include Dopi::Credentials

        def validate
          super
          log_validation_method('quiet_valid?', CommandParsingError)
          validate_credentials
        end

        def sshpass_bin
          @sshpass_bin ||= ENV['PATH'].split(':').map{|p| File.join(p, 'sshpass')}.find do |f|
            File.exists?(f) && File.executable?(f)
          end
        end

        def sshpass_cmd
          @sshpass_cmd ||= sshpass_bin ? sshpass_bin + ' -e ' : ""
        end

        def global_options
          options = []
          options << ' -o StrictHostKeyChecking=no' unless Dopi.configuration.ssh_check_host_key
          options << ' -q' if quiet
        end

        # This method adds the depricated ssh_root_pass to the credentials hash
        def credentials_with_deprications
          c = if File.exists?(Dopi.configuration.ssh_key)
            credentials + [ DopCommon::Credential.new('depricated_ssh_key', {
              :type        => :ssh_key,
              :username    => Dopi.configuration.ssh_user,
              :private_key => Dopi.configuration.ssh_key
            })]
          else
            credentials
          end
          if Dopi.configuration.ssh_pass_auth && sshpass_bin && @node.ssh_root_pass
            c + [ DopCommon::Credential.new('depricated_ssh_root_pass', {
              :type     => :username_password,
              :username => Dopi.configuration.ssh_user,
              :password => @node.ssh_root_pass
            })]
          else
            c
          end
        end

        def supported_credential_types
          [:username_password, :ssh_key]
        end

        def ssh_command_string
          # TODO: Replace this with the normal credentials hash once we can retire the ssh_root_pass method
          credentials_with_deprications.each do |credential|
            if credential.type == :username_password && !sshpass_bin
              Dopi.log.warn('ssh password login disabled because sshpass is not installed')
              next
            end
            # check connection and return command string if it is working
            c = create_command(credential)
            return c if run_command(c[:env], c[:command] + ' exit')
            log(:warn, "Unable to login with credential #{credential.name}")
          end
          cred_names = credentials_with_deprications.map{|c| c.name}.join(', ')
          raise CommandConnectionError,
            "Can't establish connection with node #{@node.name} with any of the given credentials #{cred_names}"
        end

        def create_command(credential)
          test_command_string = case credential.type
          when :username_password then
            {
              :command => "#{sshpass_cmd}ssh #{global_options.join(' ')} #{credential.username}@#{@node.name}",
              :env     => {'SSHPASS' => credential.password}
            }
          when :ssh_key then
            options = global_options.dup
            options << ' -o ChallengeResponseAuthentication=no'
            options << ' -o PasswordAuthentication=no'
            options << " -i #{credential.public_key}"
            { :command => "ssh #{options.join(' ')} #{credential.username}@#{@node.name}", :env => {}}
          end
        end

        def escape_string(string)
          string.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
        end

        def env_string
          node_env = env.reject{|variable,value| variable == 'SSHPASS'}
          escape_string(node_env.collect{|k,v| "#{k}=#{v}"}.join(' '))
        end

        def env
          super.merge(ssh_command_string[:env])
        end

        def command_string
          ssh_command_string[:command] + " \"#{env_string} #{escape_string(super)}\""
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
