module Dopi
  class Command
    class Winrm
      class Powershell < Dopi::Command::Winrm::Cmd

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = winrm_powershell_command(command_string)
          check_output(cmd_stdout) &&
            check_output(cmd_stderr) &&
            check_exit_code(cmd_exit_code)
        end

      end
    end
  end
end
