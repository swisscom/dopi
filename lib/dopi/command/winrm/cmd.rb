#
# DOPi Plugin: WinRM Command
#
require 'winrm'

module Dopi
  class Command
    module Winrm
      class Cmd < Dopi::Command
        include Dopi::ExitCodeParser
        include Dopi::OutputParser
        include Dopi::Credentials

        def validate
          log_validation_method('arguments_valid?', CommandParsingError)
          # Skip validation in subclasses that overwrite the non optional methods
          unless Dopi::Command::Winrm::Cmd > self.class && self.method(:exec).owner == self.class
            log_validation_method('exec_valid?', CommandParsingError)
          end
          log_validation_method('port_valid?')
          log_validation_method('ssl_valid?')
          log_validation_method('ca_trust_path_valid?')
          log_validation_method('disable_sspi_valid?')
          log_validation_method('basic_auth_only_valid?')
          log_validation_method('expect_exit_codes_valid?', CommandParsingError)
          validate_output_parser
          validate_credentials
        end

        def run
          result = []
          cmd_stdout, cmd_stderr, cmd_exit_code = run_command
          result << check_output(cmd_stdout)
          result << check_output(cmd_stderr)
          result << check_exit_code(cmd_exit_code)
          result.all?
        end

        def run_command
          cmd_stdout = ""
          result = winrm.cmd(exec) do |stdout, stderr|
            unless stdout.nil? or stdout.empty?
              cmd_stdout << stdout
              log(:debug, stdout)
            end
            unless stderr.nil? or stderr.empty?
              cmd_stderr << stderr
              log(:error, stderr)
            end
          end
          [cmd_stdout, cmd_stdout, result[:exitcode]]
        end

        def winrm
          winrm_service = nil
          credentials.each do |credential|
            begin
              wr = WinRM::WinRMWebService.new(
                endpoint,
                auth_method(credential),
                :realm           => credential.realm,
                :service         => credential.service,
                :keytab          => credential.keytab,
                :user            => credential.username,
                :pass            => credential.password,
                :disable_sspi    => disable_sspi,
                :basic_auth_only => basic_auth_only,
                :ca_trust_path   => ca_trust_path
              )
              wr.cmd('ipconfig') # test connection (TODO: maybe there is a better way)
            rescue WinRM::WinRMAuthorizationError, GSSAPI::GssApiError => e
              log(:warn, "Unable to login with credential #{credential.name} : #{e.message}")
            else winrm_service = wr
            end
          end
          winrm_service or
            raise CommandExecutionError, "Unable to login with any of the given credentials"
        end

        def exec
          exec_valid? ? hash[:exec] : nil
        end

        def arguments
          arguments_valid? ? parse_arguments : ""
        end

        def endpoint
          "http://#{@node.name}:#{port}/wsman"
        end

        def port
          port_valid? ? hash[:port] : '5985'
        end

        def ssl
          ssl_valid? ? hash[:ssl] : true
        end

        def ca_trust_path
          ca_trust_path_valid? ? hash[:ca_trust_path] : nil
        end

        def disable_sspi
          disable_sspi_valid? ? hash[:disable_sspi_valid] : nil
        end

        def basic_auth_only
          basic_auth_only_valid? ? hash[:basic_auth_only] : nil
        end

      private

        def supported_credential_types
          [:username_password, :kerberos]
        end

        def auth_method(credential)
          case credential.type
          when :kerberos then :kerberos
          when :username_password then ssl ? :ssl : :plaintext
          end
        end

        def exec_valid?
          hash[:exec] or
            raise CommandParsingError, "No command to execute in 'exec' defined"
          hash[:exec].kind_of?(String) or
            raise CommandParsingError, "The value for 'exec' has to be a String"
        end

        def arguments_valid?
          return false unless hash.kind_of?(Hash) # plugin may not have parameters
          return false if hash[:arguments].nil? # arguments are optional
          hash[:arguments].kind_of?(Hash) or
            hash[:arguments].kind_of?(Array) or
            hash[:arguments].kind_of?(String) or
            raise CommandParsingError, "The value for 'arguments' hast to be an Array, Hash or String"
        end

        def parse_arguments
          case hash[:arguments]
          when Hash   then hash[:arguments].to_a.flatten.join(' ')
          when Array  then hash[:arguments].flatten.join(' ')
          when String then hash[:arguments]
          else ""
          end
        end

        def port_valid?
          #TODO: implement proper validation
          hash[:port]
        end

        def ssl_valid?
          #TODO: implement proper validation
          hash[:ssl_valid]
        end

        def ca_trust_path_valid?
          #TODO: implement proper validation
          hash[:ca_trust_path]
        end

        def disable_sspi_valid?
          #TODO: implement proper validation
          hash[:disable_sspi]
        end

        def basic_auth_only_valid?
          #TODO: implement proper validation
          hash[:basic_auth_only]
        end

        def expect_exit_codes_defaults
          0
        end

        def parse_output_defaults
          nil
        end

      end
    end
  end
end
