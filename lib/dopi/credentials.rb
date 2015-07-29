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
      if hash[:credentials].kind_of?(String)
        @step.plan.credentials.has_key?(hash[:credentials]) or
          raise CommandParsingError, "Credentials #{hash[:credentials]} are not configured"
      end
      if hash[:credentials].kind_of?(Array)
        hash[:credentials].each do |c|
          c.kind_of?(String) or
            raise CommandParsingError, "All values in the 'credentials' array have to be strings"
          @step.plan.credentials.has_key?(c) or
            raise CommandParsingError, "Credentials #{c} are not configured"
        end
      end
      true
    end

    def parse_credentials
      [hash[:credentials]].flatten.map{|c| @step.plan.credentials[c]}
    end

  end
end


