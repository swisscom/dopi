# DOPi Plugin: Custom Command
#
# TODO: Refactor and document
#  - fail_on_warning
#  - parsing
#
require 'open3'

module Dopi
  class Command
    class Custom < Dopi::Command
      include Dopi::ExitCodeParser

    public

      def validate
        log_validation_method('env_valid?', CommandParsingError)
        log_validation_method('arguments_valid?', CommandParsingError)
        log_validation_method('expect_exit_codes_valid?', CommandParsingError)
        # Skip validation in subclasses that overwrite the non optional methods
        unless Dopi::Command::Custom > self.class && self.method(:exec).owner == self.class
          log_validation_method('exec_valid?', CommandParsingError)
        end
      end

      def run
        result = []
        cmd_stdout, cmd_stderr, cmd_exit_code = run_command
        result << parse_output(cmd_stdout)
        result << parse_output(cmd_stderr)
        result << check_exit_code(cmd_exit_code)
        result.all?
      end

      def exec
        @exec ||= exec_valid? ?
          hash[:exec] : nil
      end

      def env
        @env ||= env_valid? ?
          env_defaults.merge(hash[:env]) : env_defaults
      end

      def arguments
        @arguments ||= arguments_valid? ?
          parse_arguments : ""
      end

    private

      def exec_valid?
        hash[:exec] or
          raise CommandParsingError, "No command to execute in 'exec' defined"
        hash[:exec].kind_of?(String) or
          raise CommandParsingError, "The value for 'exec' has to be a String"
      end

      def env_valid?
        return false unless hash.kind_of?(Hash) # plugin may not have parameters
        return false if hash[:env].nil? # env is optional
        hash[:env].kind_of?(Hash) or
          raise CommandParsingError, "The value for 'env' has to be a hash"
      end

      def env_defaults
        { 'DOP_NODE_FQDN' => @node.name }
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

      def expect_exit_codes_defaults
        0
      end

      def command_string
        exec + ' ' + arguments
      end

      # The command method executes the command of the step.
      # Returns an array with stdio, sterror and exit code.
      def run_command
        cmd_stdout = ''
        cmd_stderr = ''
        log(:debug, "Executing #{command_string} for command #{name}")
        log(:debug, "Environment: #{env.to_s}")
        cmd_exit_code = Open3.popen3(env, command_string) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          stdout_thread= Thread.new do
            until ( line = stdout.gets ).nil? do
              cmd_stdout << line
              log(:debug, line.gsub("\n", '').gsub("\r", ''))
            end
          end
          stderr_thread = Thread.new do
            until ( line = stderr.gets ).nil? do
              cmd_stderr << line
              log(:error, line.gsub("\n", '').gsub("\r", ''))
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
          log(:debug, "No patterns defined to parse the output of command #{name}")
          return true
        else
          if patterns[:error].class == Array
            errors = match_patterns(raw_output, patterns[:error])
            errors.each do |error|
              log(:error, "ERROR detected in output")
              log(:error, error)
            end
          end
          if patterns[:warning].class == Array
            warnings = match_patterns(raw_output, patterns[:warning])
            warnings.each do |warning|
              log(:warn, "Warning detected in output")
              log(:warn, warning)
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
    end

  end
end
