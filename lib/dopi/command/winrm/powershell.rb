module Dopi
  class Command
    class Winrm
      class Powershell < Dopi::Command::Winrm::Cmd

        alias :original_exec :exec

        def original_command_string
          original_exec + ' ' + arguments
        end

        def exec
          script = WinRM::PowershellScript.new(super)
          "powershell -encodedCommand #{script.encoded()}"
        end

        def run
          log(:debug, "Original command was: '#{original_command_string}' for command #{name}")
          super
        end

        def run_noop
          log(:info, "(NOOP) Original command was: '#{original_command_string}' for command #{name}")
          super
        end

      end
    end
  end
end
