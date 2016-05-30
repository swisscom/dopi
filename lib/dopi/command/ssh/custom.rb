#
# SSH custom command
#

module Dopi
  class Command
    class Ssh
      class Custom < Dopi::Command::Custom
        include Dopi::CommandParser::Credentials

        def validate
          super
          log_validation_method(:port_valid?, CommandParsingError)
          log_validation_method(:quiet_valid?, CommandParsingError)
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
          options << " -p #{port}"
          options << ' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' unless Dopi.configuration.ssh_check_host_key
          options << ' -q' if quiet
        end

        def supported_credential_types
          [:username_password, :ssh_key]
        end

        def reset_ssh_command_string
          @ssh_command_string = nil
        end

        def ssh_command_string(connection_test = true)
          @ssh_command_string ||= if connection_test
            working_ssh_command_string
          else
            create_ssh_command_string(credentials.first, @node.addresses)
          end
        end

        def working_ssh_command_string
          credentials.each do |credential|
            if credential.type == :username_password && !sshpass_bin
              Dopi.log.warn('ssh password login disabled because sshpass is not installed')
              next
            end
            # check connection and return command string if it is working
            c = create_ssh_command_string(credential, @node.address(port))
            return c if local_command(c[:env], c[:command] + ' exit')[2] == 0
            log(:warn, "Unable to login with credential #{credential.name}")
          end
          cred_names = credentials.map{|c| c.name}.join(', ')
          raise CommandConnectionError,
            "Can't establish connection with node #{@node.name} with any of the given credentials #{cred_names}"
        end

        def create_ssh_command_string(credential, address)
          case credential.type
          when :username_password then
            {
              :command => "#{sshpass_cmd}ssh #{global_options.join(' ')} #{credential.username}@#{address}",
              :env     => {'SSHPASS' => credential.password}
            }
          when :ssh_key then
            options = global_options.dup
            options << ' -o ChallengeResponseAuthentication=no'
            options << ' -o PasswordAuthentication=no'
            options << " -i #{credential.private_key}"
            { :command => "ssh #{options.join(' ')} #{credential.username}@#{@node.address(22)}", :env => {}}
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

        def run
          reset_ssh_command_string
          super
        end

        def run_noop
          reset_ssh_command_string
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
          log(:info, "(NOOP) Environment: #{env.to_s}")
        rescue Dopi::ConnectionError
          reset_ssh_command_string
          log(:info, "(NOOP) Unable to connect to the node and check what credentials/address to use. Showing example")
          ssh_command_string(false) # generate an example ssh_command_string
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
          log(:info, "(NOOP) Environment: #{env.to_s}")
        end

        def port
          @port ||= port_valid? ? hash[:port].to_s : '22'
        end

        def quiet
          @quiet || quiet_valid? ? hash[:quiet] : true
        end

        def port_valid?
          return false unless hash.kind_of?(Hash)
          return false if hash[:port].nil? # is optional
          hash[:port].kind_of?(Fixnum) or
            raise CommandParsingError, "Plugin #{name}: The value for port must be a number"
          hash[:port].between?(0, 65536) or
            raise CommandParsingError, "Plugin #{name}: The value for port must bigger than 0 and below 65536"
          true
        end

        def quiet_valid?
          return false unless hash.kind_of?(Hash)
          return false if hash[:quiet].nil? # is optional
          hash[:quiet].kind_of?(TrueClass) or hash[:quiet].kind_of?(FalseClass) or
            raise CommandParsingError, "Plugin #{name}: The value for quiet must be boolean"
        end

      end
    end
  end
end
