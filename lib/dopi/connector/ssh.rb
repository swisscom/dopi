#
# This connector will execute commands over ssh
#
#
module Dopi
  module Connector
    module Ssh
      include Dopi::Connector::Local
      include Dopi::CommandParser::Credentials

    public

      def validate_ssh
        log_validation_method(:port_valid?, CommandParsingError)
        log_validation_method(:quiet_valid?, CommandParsingError)
        log_validation_method(:check_host_key_valid?, CommandParsingError)
        log_validation_method(:base64_valid?, CommandParsingError)
        log_validation_method(:ssh_options_valid?, CommandParsingError)
        validate_credentials
      end

      def ssh_command(env, command_string)
        credential = working_ssh_credential
        ssh_command_string = create_ssh_command_string(credential, env, command_string)
        local_env = create_local_env(credential)
        local_env.merge!(env) unless base64 # keep old behaviour for escaping
        local_command(local_env, ssh_command_string)
      end

      def port
        @port ||= port_valid? ? hash[:port].to_s : '22'
      end

      def quiet
        @quiet || quiet_valid? ? hash[:quiet] : true
      end

      def check_host_key
        @check_host_key || check_host_key_valid? ? hash[:check_host_key] : false
      end

      def base64
        @base64 || base64_valid? ? hash[:base64] : true
      end

      def ssh_options
        #TBD
        []
      end

    private

      def supported_credential_types
        [:username_password, :ssh_key]
      end

      # this method checks for every credential if a login is possible
      # and will return the first one where it is possible.
      # If none of the credentials work it will raise a CommandConnectionError.
      def working_ssh_credential
        credentials.find do |credential|
          ssh_command_string = create_ssh_command_string(credential, {}, 'exit')
          local_env = create_local_env(credential)
          local_command(local_env, ssh_command_string)[2] == 0
        end or raise CommandConnectionError,
          "Can't establish connection with node #{@node.name} with any of the given" +
          "credentials #{credentials.map{|c| c.name}.join(', ')}"
      end

      def create_local_env(credential)
        if credential.type == :username_password
          { 'SSHPASS' => credential.password }
        else
          {}
        end
      end

      def create_ssh_command_string(credential, env, command_string)
        address = @node.address(port)
        opts = options(credential)
        prefix = credential.type == :username_password ? sshpass_cmd : ''
        cmd = "#{ssh_env_string(env)} #{command_string}"
        real_cmd = if base64
          log(:debug, "Unencoded command: '#{cmd}'")
          ssh_encode_command(cmd)
        else
          ssh_escape_command(cmd)
        end
        "#{prefix}ssh #{opts} #{credential.username}@#{address} \"#{real_cmd}\""
      end

      def options(credential)
        opts = []
        opts << "-p #{port}"
        opts << '-q' if quiet
        opts << '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' unless check_host_key
        if credential.type == :ssh_key
          opts << '-o ChallengeResponseAuthentication=no'
          opts << '-o PasswordAuthentication=no'
          opts << "-i #{credential.private_key}"
        end
        opts += ssh_options
        opts += ssh_options_defaults if respond_to?(:ssh_options_defaults)
        opts.join(' ')
      end

      def sshpass_bin
        @sshpass_bin ||= ENV['PATH'].split(':').map{|p| File.join(p, 'sshpass')}.find do |f|
          File.exists?(f) && File.executable?(f)
        end
      end

      def sshpass_cmd
        @sshpass_cmd ||= sshpass_bin ? sshpass_bin + ' -e ' : ""
      end

      def ssh_env_string(env)
        env.map{|variable,value| "export #{variable}=#{value};" }.join(' ')
      end

      def ssh_escape_command(cmd)
        cmd.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
      end

      def ssh_encode_command(cmd)
        "echo -n #{Base64.strict_encode64(cmd)} | base64 -d | bash"
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
          raise CommandParsingError, "Plugin #{name}: The value for 'quiet' must be boolean"
      end

      def check_host_key_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:check_host_key].nil? # is optional
        hash[:check_host_key].kind_of?(TrueClass) or hash[:check_host_key].kind_of?(FalseClass) or
          raise CommandParsingError, "Plugin #{name}: The value for 'check_host_key' must be boolean"
      end

      def base64_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:base64].nil? # is optional
        hash[:base64].kind_of?(TrueClass) or hash[:base64].kind_of?(FalseClass) or
          raise CommandParsingError, "Plugin #{name}: The value for 'base64' must be boolean"
      end

      def ssh_options_valid?
        #TBD
        false
      end

    end
  end
end
