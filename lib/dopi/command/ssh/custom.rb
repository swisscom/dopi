#
# DOPi Plugin: Custom Command
#

module Dopi
  class Command
    class Ssh
      class Custom < Dopi::Command
        include Dopi::Connector::Ssh
        include Dopi::CommandParser::Exec
        include Dopi::CommandParser::Env
        include Dopi::CommandParser::Arguments
        include Dopi::CommandParser::ExitCode
        include Dopi::CommandParser::Output

      public

        def validate
          validate_ssh
          validate_exec
          validate_env
          validate_arguments
          validate_exit_code
          validate_output
        end

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = ssh_command(env, command_string)
          check_output(cmd_stdout) &&
            check_output(cmd_stderr) &&
            check_exit_code(cmd_exit_code)
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
end
