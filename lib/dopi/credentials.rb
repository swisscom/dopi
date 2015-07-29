#
# Dopi Credentials helper module
#
# This module will provide a credentials method which contains all the credential
# objects for the plugin.
#
# Make sure you call "validate_credentials" method from your validation method.
#
# Implement a method "supported_credential_types" in your plugin if you want to limit
# the types which are supported and trow an error during validation if some other type
# is assigned
#
module Dopi
  module Credentials
    include DopCommon::Validator

  public

    def validate_credentials
      log_validation_method('credentials_valid?', CommandParsingError)
    end

    def credentials
      @credentials ||= credentials_valid? ? parse_credentials : []
    end

  private

    def credentials_valid?
      return false unless hash.kind_of?(Hash) # plugin may not have parameters
      return false if hash[:credentials].nil? # credentials is optional
      hash[:credentials].kind_of?(String) or hash[:credentials].kind_of?(Array) or
        raise CommandParsingError, "the value for 'credentials' has to be a string or an array of strings"
      [hash[:credentials]].flatten.each do |c|
        c.kind_of?(String) or
          raise CommandParsingError, "All values in the 'credentials' array have to be strings"
        @step.plan.credentials.has_key?(c) or
          raise CommandParsingError, "Credentials #{c} are not configured"
        if self.methods.include?(:supported_credential_types)
          cred_type = @step.plan.credentials[c].type
          supported_credential_types.include?(cred_type) or
            raise CommandParsingError, "Credential #{c} is of type #{cred_type}, which is not supported by the plugin"
        end
      end
      true
    end

    def parse_credentials
      [hash[:credentials]].flatten.map{|c| @step.plan.credentials[c]}
    end

  end
end


