#
# This is a mixin for command plugins that need to parse an exit Code of some sort
#
# Make sure you add the validation method to the plugin validation and
# implement the expect_exit_codes_defaults method.
#
module Dopi
  module ExitCodeParser

  public

    def expect_exit_codes
      @expect_exit_codes ||= expect_exit_codes_valid? ?
        hash[:expect_exit_codes] : expect_exit_codes_defaults
    end

  private

    def expect_exit_codes_valid?
      return false unless hash.kind_of?(Hash) # plugin may not have parameters
      return false if hash[:expect_exit_codes].nil? # expect_exit_codes is optional
      hash[:expect_exit_codes].kind_of?(Fixnum) or
        hash[:expect_exit_codes].kind_of?(String) or
        hash[:expect_exit_codes].kind_of?(Symbol) or
        hash[:expect_exit_codes].kind_of?(Array) or
        raise CommandParsingError, "The value for 'expect_exit_codes' hast to be a number or an array of numbers or :all"
      if hash[:expect_exit_codes].kind_of?(String) || hash[:expect_exit_codes].kind_of?(Symbol)
        ['all', 'All', 'ALL', :all].include? hash[:expect_exit_codes] or
          raise CommandParsingError, "Unknown keyword for expect_exit_codes. This has to be a number, an array or :all"
      end
      if hash[:expect_exit_codes].kind_of?(Array)
        hash[:expect_exit_codes].all?{|exit_code| exit_code.kind_of?(Fixnum)} or
          raise CommandParsingError, "The array in 'expect_exit_codes' can only contain numbers"
      end
      true
    end

    # Returns true if the exit code is one we expected, otherwise false
    def check_exit_code(cmd_exit_code)
      exit_code_ok = case expect_exit_codes
      when 'all', 'ALL', 'All', :all then true
      when Array then expect_exit_codes.include?(cmd_exit_code)
      when Fixnum then expect_exit_codes == cmd_exit_code
      else false
      end

      unless exit_code_ok
        log(:error, "Wrong exit code in command #{name}")
        if expect_exit_codes.kind_of?(Array)
          log(:error, "Exit code was #{cmd_exit_code.to_s} should be one of #{expect_exit_codes.join(', ')}")
        elsif expect_exit_codes.kind_of?(Fixnum)
          log(:error, "Exit code was #{cmd_exit_code.to_s} should be #{expect_exit_codes.to_s}")
        else
          log(:error, "Exit code was #{cmd_exit_code.to_s} #{expect_exit_codes}")
        end
      end

      exit_code_ok
    end

  end
end
