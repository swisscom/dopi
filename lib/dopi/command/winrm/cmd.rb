#
# DOPi Plugin: WinRM Command
#
require 'winrm'

module Dopi
  class Command
    class Winrm
      class Cmd < Dopi::Command
        include Dopi::Connector::Winrm
        include Dopi::CommandParser::Exec
        include Dopi::CommandParser::Env
        include Dopi::CommandParser::Arguments
        include Dopi::CommandParser::ExitCode
        include Dopi::CommandParser::Output

        def validate
          validate_winrm
          validate_exec
          validate_env
          validate_arguments
          validate_exit_code
          validate_output
        end

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = winrm_command(command_string)
          check_output(cmd_stdout) &&
            check_output(cmd_stderr) &&
            check_exit_code(cmd_exit_code)
        end

        def run_noop
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
        end

        def command_string
          exec + ' ' + arguments
        end

      end
    end
  end
end
