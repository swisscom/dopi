#
# DOPi Plugin: Custom Command
#
require 'open3'

module Dopi
  class Command
    class Custom < Dopi::Command
      include Dopi::ExitCodeParser
      include Dopi::OutputParser

    public
      def validate
        log_validation_method('env_valid?', CommandParsingError)
        log_validation_method('arguments_valid?', CommandParsingError)
        # Skip validation in subclasses that overwrite the non optional methods
        unless Dopi::Command::Custom > self.class && self.method(:exec).owner == self.class
          log_validation_method('exec_valid?', CommandParsingError)
        end
        validate_exit_code_parser
        validate_output_parser
      end

      def run
        result = []
        cmd_stdout, cmd_stderr, cmd_exit_code = run_command
        # Output Parser
        result << check_output(cmd_stdout)
        result << check_output(cmd_stderr)
        # Exit Code Parser
        result << check_exit_code(cmd_exit_code)
        result.all?
      end

      def run_noop
        log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
        log(:info, "(NOOP) Environment: #{env.to_s}")
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

      def parse_output_defaults
        nil
      end

      # assemble the command to execute
      def command_string
        exec + ' ' + arguments
      end

      # The command method executes the command of the step.
      # Returns an array with stdio, sterror and exit code.
      def run_command(env = env, command_string = command_string)
        cmd_stdout = ''
        cmd_stderr = ''
        log(:debug, "Executing #{command_string} for command #{name}")
        log(:debug, "Environment: #{env.to_s}")
        cmd_exit_code = Open3.popen3(env, command_string, :pgroup => true) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          stdout_thread = Thread.new do
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

    end
  end
end
