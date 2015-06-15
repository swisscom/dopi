# DOPi Plugin: Custom Command
#
# This DOPi Plugin will execute a customized command on the
# node DOPi is running on. It will run the command once per
# node in the step and export the node fqdn in the
# environment variable DOP_NODE_FQDN
#
# Plugin Settings:
#
# exec
# The command the plugin should execute for every node.
#
# arguments (optional)
# The arguments for the command. This can be set by a string
# as an array or as a hash. All the elements of the hash and
# the array will be flattened and joined with a space.
# default: ""
#
# env (optional)
# The environment variables that should be set
# default: { DOP_NODE_FQDN => fqdn_of_node }
#
# expect_exit_codes (optional)
# The exit codes DOPi should expect if the program terminates.
# It the program exits with an exit code not listed here, DOPi
# will mark the run as failed. The values can be a number, an
# array of numbers or :all for all possible exit codes.
# default: 0
#
#
# TODO: Refactor
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
        unless Dopi::Command::Custom > self.class and respond_to?('exec')
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
        Dopi.log.debug("Executing #{command_string} for command #{name}")
        Dopi.log.debug("Environment: #{env.to_s}")
        cmd_exit_code = Open3.popen3(env, command_string) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          stdout_thread= Thread.new do
            until ( line = stdout.gets ).nil? do
              cmd_stdout << line
              Dopi.log.info(@node.name + ":" + name + " - " + line.gsub("\n", '').gsub("\r", ''))
            end
          end
          stderr_thread = Thread.new do
            until ( line = stderr.gets ).nil? do
              cmd_stderr << line
              Dopi.log.error(@node.name + ":" + name + " - " + line.gsub("\n", '').gsub("\r", ''))
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
    end

  end
end
