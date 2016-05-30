#
# This is a mixin for command plugins that need to parse an output of some sort
#
# Make sure to call the validation method from the class you use the module
#
module Dopi
  module CommandParser
    module Output
      include DopCommon::Validator

    public

      def validate_output
        log_validation_method('parse_output_valid?', CommandParsingError)
        unless parse_output.empty?
          log_validation_method('error_patterns_valid?', CommandParsingError)
          log_validation_method('warning_patterns_valid?', CommandParsingError)
        end
        log_validation_method('fail_on_warning_valid?', CommandParsingError)
      end

      def check_output(raw_output)
        if error_patterns.empty? && warning_patterns.empty?
          log(:debug, "No patterns defined to parse the output")
          return true
        end

        output_ok = true

        error_patterns.each do |pattern|
          lines_with_matches(raw_output, pattern).each do |line_with_error|
            log(:error, line_with_error)
            output_ok = false
          end
        end

        warning_patterns.each do |pattern|
          lines_with_matches(raw_output, pattern).each do |line_with_warning|
            if fail_on_warning
              log(:error, line_with_warning)
              output_ok = false
            else
              log(:warn, line_with_warning)
            end
          end
        end

        output_ok
      end

      def parse_output
        @parse_output ||= parse_output_valid? ?
          Hash[hash[:parse_output].map{|k,v| [k.to_sym, v]}] :
          (parse_output_defaults || {})
      end

      def error_patterns
        @error_patterns ||= parser_patterns_valid?(parse_output[:error]) ?
          [ parse_output[:error] ].flatten : []
      end

      def warning_patterns
        @warning_patterns ||= parser_patterns_valid?(parse_output[:warning]) ?
          [ parse_output[:warning] ].flatten : []
      end

      def fail_on_warning
        @fail_on_warning ||= fail_on_warning_valid? ?
          hash[:fail_on_warning] : false
      end

      def lines_with_matches(raw_output, pattern)
        regexp = Regexp.new(pattern)
        raw_output.lines.find_all{ |line| line.scan(regexp).any? }
      end

    private

      def parse_output_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:parse_output].nil? # optional
        hash[:parse_output].kind_of?(Hash) or
          raise CommandParsingError, "The value for 'parse_output' has to be a Hash"
        true
      end

      def error_patterns_valid?
        parser_patterns_valid?(parse_output[:error])
      end

      def warning_patterns_valid?
        parser_patterns_valid?(parse_output[:warning])
      end

      def parser_patterns_valid?(pattern)
        return false if pattern.nil? # optional
        pattern.kind_of?(Array) or
          raise CommandParsingError, "The value of 'error' and 'warning' in 'parse_output' has to be an Array"
        pattern.each do |entry|
          begin
            Regexp.new(entry)
          rescue
            raise CommandParsingError, "The pattern #{entry} in 'parse_output' is not a valid regular expression"
          end
        end
        true
      end

      def fail_on_warning_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:fail_on_warning].nil? # is optional
        hash[:fail_on_warning].kind_of?(TrueClass) or hash[:fail_on_warning].kind_of?(FalseClass) or
          raise CommandParsingError, "The value for 'fail_on_warning' must be boolean"
        true
      end

    end
  end
end


