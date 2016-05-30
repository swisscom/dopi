#
# Simple command parser module for exec
#
module Dopi
  module CommandParser
    module Exec

      def validate_exec
        log_validation_method('exec_valid?', CommandParsingError)
      end

      def exec
        exec_valid? ? hash[:exec] : nil
      end

    private

      def exec_valid?
        hash[:exec] or
          raise CommandParsingError, "No command to execute in 'exec' defined"
        hash[:exec].kind_of?(String) or
          raise CommandParsingError, "The value for 'exec' has to be a String"
      end

    end
  end
end
