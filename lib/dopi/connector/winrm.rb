#
# DOPi Plugin: WinRM Command
#
require 'winrm'
require 'gssapi'

module Dopi
  module Connector
    module Winrm
      include Dopi::CommandParser::Credentials

      def validate_winrm
        log_validation_method(:port_valid?)
        log_validation_method(:ssl_valid?)
        log_validation_method(:ca_trust_path_valid?)
        log_validation_method(:disable_sspi_valid?)
        log_validation_method(:basic_auth_only_valid?)
        validate_credentials
      end

      def winrm_command(command_string, use_shell = :cmd)
        cmd_stdout = ""
        cmd_stderr = ""
        log(:debug, "Executing '#{command_string}' for command #{name}")
        winrm.shell(use_shell) do |shell|
          result = shell.run(command_string) do |stdout, stderr|
            unless stdout.nil? or stdout.empty?
              cmd_stdout << stdout
              log(:debug, stdout)
            end
            unless stderr.nil? or stderr.empty?
              cmd_stderr << stderr
              log(:error, stderr)
            end
          end
          return [cmd_stdout, cmd_stderr, result.exitcode]
        end
      end

      def winrm_powershell_command(command_string)
        winrm_command(command_string, :powershell)
      end

      def winrm
        working_winrm_connection = nil
        credentials.each do |credential|
          begin
            winrm_connection = WinRM::Connection.new(
              :endpoint          => endpoint,
              :transport         => auth_method(credential),
              :realm             => credential.realm,
              :service           => credential.service,
              :keytab            => credential.keytab,
              :user              => credential.username,
              :password          => credential.password,
              :disable_sspi      => disable_sspi,
              :basic_auth_only   => basic_auth_only,
              :ca_trust_path     => ca_trust_path,
              :operation_timeout => operation_timeout,
            )
            winrm_connection.shell(:cmd) do |shell|
              output = shell.run('exit') # test connection
              if output.exitcode == 0
                working_winrm_connection = winrm_connection
              end
            end
          rescue WinRM::WinRMAuthorizationError, GSSAPI::GssApiError => e
            log(:warn, "Unable to login with credential #{credential.name} : #{e.message}")
          rescue SocketError => e
            raise CommandConnectionError,
              "A problem occurred while trying to connect to node #{@node.name} : #{e.message}"
          rescue WinRM::WinRMWMIError => e
            raise CommandExecutionError,
              "A problem occurred while trying to connect to node #{@node.name} : #{e.message}"
          end
        end
        working_winrm_connection or
          raise CommandExecutionError,
            "Unable to login with any of the given credentials: #{credentials.map{|c| c.name}.join(', ')}"
      end

      def endpoint
        "http://#{@node.address(port)}:#{port}/wsman"
      end

      def port
        port_valid? ? hash[:port] : 5985
      end

      def ssl
        ssl_valid? ? hash[:ssl] : true
      end

      def ca_trust_path
        ca_trust_path_valid? ? hash[:ca_trust_path] : nil
      end

      def disable_sspi
        disable_sspi_valid? ? hash[:disable_sspi] : nil
      end

      def basic_auth_only
        basic_auth_only_valid? ? hash[:basic_auth_only] : nil
      end

      def operation_timeout
        operation_timeout_valid? ? hash[:operation_timeout] : ( plugin_timeout - 5 )
      end

      def supported_credential_types
        [:username_password, :kerberos]
      end

    private

      def auth_method(credential)
        case credential.type
        when :kerberos then :kerberos
        when :username_password then ssl ? :ssl : :plaintext
        end
      end

      def port_valid?
        return false if hash.nil?
        return false if hash[:port].nil?
        hash[:port].kind_of?(Fixnum) and (hash[:port] > 0) and (hash[:port] < 65536) or
          raise CommandParsingError, "The value for 'port' has to be a number in the range of 1-65535"
      end

      def ssl_valid?
        return false if hash.nil?
        return false if hash[:ssl].nil?
        hash[:ssl].kind_of?(TrueClass) or hash[:ssl].kind_of?(FalseClass) or
          raise CommandParsingError, "The value for 'ssl_valid' has to be true or false"
      end

      def ca_trust_path_valid?
        return false if hash.nil?
        return false if hash[:ca_trust_path].nil?
        hash[:ca_trust_path].kind_of?(String) or
          raise CommandParsingError, "The value for ca_trust_path has to be a string"
        File.directory?(hash[:ca_trust_path]) or
          raise CommandParsingError, "The directory in 'ca_trust_path' does not exist"
      end

      def disable_sspi_valid?
        return false if hash.nil?
        return false if hash[:disable_sspi].nil?
        hash[:disable_sspi].kind_of?(TrueClass) or hash[:disable_sspi].kind_of?(FalseClass) or
          raise CommandParsingError, "The value for 'disable_sspi' has to be true or false"
      end

      def basic_auth_only_valid?
        return false if hash.nil?
        return false if hash[:basic_auth_only].nil?
        hash[:basic_auth_only].kind_of?(TrueClass) or hash[:basic_auth_only].kind_of?(FalseClass) or
          raise CommandParsingError, "The value for 'basic_auth_only' has to be true or false"
      end

      def operation_timeout_valid?
        return false if hash.nil?
        return false if hash[:operation_timeout].nil?
        hash[:operation_timeout].kind_of?(Fixnum) or
          raise CommandParsingError, 'The value for operation_timeout has to be a number'
        hash[:operation_timeout] >= 0 or
          raise CommandParsingError, 'The value for operation_timeout has to be positive number'
      end

    end
  end
end
