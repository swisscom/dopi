#
# DOPi command base class
#
# TODO: Refactor
require 'open3'

module Dopi
  class Command
    class Custom < Dopi::Command

    public

      def validate
        log_validation_method('env_valid?', CommandParsingError)
        log_validation_method('arguments_valid?', CommandParsingError)
        log_validation_method('expect_exit_codes_valid?', CommandParsingError)
      end

      def run
        result = []
        cmd_stdout, cmd_stderr, cmd_exit_code = run_command
        result << parse_output(cmd_stdout)
        result << parse_output(cmd_stderr)
        result << check_exit_code(cmd_exit_code)
        result.all?
      end

      def env
        @env ||= env_valid? ?
          hash[:env] : {}
      end

      def arguments
        @arguments ||= arguments_valid? ?
          parse_arguments : ""
      end

      def expect_exit_codes
        @expect_exit_codes ||= expect_exit_codes_valid? ?
          hash[:expect_exit_codes] : 0
      end

    private

      def env_valid?
        return false unless hash.kind_of?(Hash) # plugin may not have parameters
        return false if hash[:env].nil? # env is optional
        hash[:env].kind_of?(Hash) or
          raise CommandParsingError, "The value for 'env' has to be a hash"
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


      def exec
        if hash[:exec]
          return hash[:exec]
        else
          raise "No exec part for command #{name}"
        end
      end


      def command_string
        exec + ' ' + arguments
      end


      # The command method executes the command of the step.
      # Returns an array with stdio, sterror and exit code.
      def run_command
        cmd_stdout = ''
        cmd_stderr = ''
        Dopi.log.debug("Executing #{command_string} for command #{name}")
        Dopi.log.debug("Environment: #{env.to_s}")
        cmd_exit_code = Open3.popen3(env, command_string) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          stdout_thread= Thread.new do
            until ( line = stdout.gets ).nil? do
              cmd_stdout << line
              Dopi.log.info(@node.name + ":" + name + " - " + line.chomp)
            end
          end
          stderr_thread = Thread.new do
            until ( line = stderr.gets ).nil? do
              cmd_stderr << line
              Dopi.log.error(@node.name + ":" + name + " - " + line.chomp)
            end
          end
          stdout_thread.join
          stderr_thread.join
          wait_thr.value
        end
        [ cmd_stdout, cmd_stderr, cmd_exit_code.exitstatus ]
      end


      # Return parser patterns if you want to hardcode
      # it to the command. This can be overwritten by
      # the 'parse_output' section in the plan
      def parser_patterns
        nil
      end


      # Parse the raw_output
      def parse_output(raw_output)
        errors = []
        warnings = []
        patterns = nil

        if parser_patterns.class == Hash
          patterns = parser_patterns
        end
        if hash.class == Hash && hash[:parse_output].class == Hash
          patterns = hash[:parse_output]
        end
        if patterns.nil?
          Dopi.log.debug("No patterns defined to parse the output of command #{name}")
          return true
        else
          if patterns[:error].class == Array
            errors = match_patterns(raw_output, patterns[:error])
            errors.each do |error|
              Dopi.log.error("ERROR detected in output of command #{name}:")
              Dopi.log.error(error)
            end
          end
          if patterns[:warning].class == Array
            warnings = match_patterns(raw_output, patterns[:warning])
            warnings.each do |warning|
              Dopi.log.warn("Warning detected in output of command #{name}:")
              Dopi.log.warn(warning)
            end
          end
        end
        if hash[:fail_on_warning]
          return false unless warnings.empty?
        end
        return false unless errors.empty?
        return true
      end


      # takes an array of patterns and a string to match
      # returns every line with a match
      def match_patterns(raw_output, patterns)
        results = []
        patterns.each do |pattern|
          begin
            regexp = Regexp.new(pattern)
            raw_output.each_line do |line|
              results << line unless line.scan(regexp).empty?
            end
          rescue RegexpError => e
            # TODO: Throw proper exception class
            raise "Error while parsing regular expression #{pattern} for command #{name}"
          end
        end
        return results
      end

      def check_exit_code(cmd_exit_code)
        exit_code_ok = case expect_exit_codes
        when 'all', 'ALL', 'All', :all then true
        when Array then expect_exit_codes.include?(cmd_exit_code)
        when Fixnum then expect_exit_codes == cmd_exit_code
        else false
        end

        unless exit_code_ok
          Dopi.log.error("Wrong exit code in command #{name} for node #{@node.name}")
          if expect_exit_codes.kind_of?(Array)
            Dopi.log.error("Exit code was #{cmd_exit_code.to_s} should be one of #{expect_exit_codes.join(', ')}")
          elsif expect_exit_codes.kind_of?(Fixnum)
            Dopi.log.error("Exit code was #{cmd_exit_code.to_s} should be #{expect_exit_codes.to_s}")
          else
            Dopi.log.error("Exit code was #{cmd_exit_code.to_s} #{expect_exit_codes}")
          end
        end

        exit_code_ok
      end

    end
  end
end
