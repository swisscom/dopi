#
# DOPi Plugin: WinRM Command
#
require 'winrm'

module Dopi
  class Command
    class Winrm < Dopi::Command
      include Dopi::Credentials

      def validate
        log_validation_method('port_valid?')
        log_validation_method('ssl_valid?')
        log_validation_method('ca_trust_path_valid?')
        log_validation_method('disable_sspi_valid?')
        log_validation_method('basic_auth_only_valid?')
        validate_credentials
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

    end
  end
end
