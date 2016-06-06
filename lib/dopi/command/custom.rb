#
# DOPi Plugin: Custom Command
#

module Dopi
  class Command
    class Custom < Dopi::Command
      include Dopi::Connector::Local
      include Dopi::CommandParser::Exec
      include Dopi::CommandParser::Env
      include Dopi::CommandParser::Arguments
      include Dopi::CommandParser::ExitCode
      include Dopi::CommandParser::Output

    public
      def validate
        #validate_exec
        # remove after the refactoring is complete
        unless Dopi::Command::Custom > self.class && self.method(:exec).owner == self.class
          log_validation_method('exec_valid?', CommandParsingError)
        end
        validate_env
        validate_arguments
        validate_exit_code
        validate_output
      end

      def run
        result = []
        cmd_stdout, cmd_stderr, cmd_exit_code = local_command(env, command_string)
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

    private

      def command_string
        exec + ' ' + arguments
      end

    end
  end
end
