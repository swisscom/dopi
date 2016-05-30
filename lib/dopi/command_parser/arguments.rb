#
# Simple command parser class to parse arguments
#
module Dopi
  module CommandParser
    module Arguments

      def validate_arguments
        log_validation_method('arguments_valid?', CommandParsingError)
      end

      def arguments
        arguments_valid? ? parse_arguments : ""
      end

    private

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

    end
  end
end
