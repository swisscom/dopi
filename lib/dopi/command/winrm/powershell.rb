module Dopi
  class Command
    class Winrm
      class Powershell < Dopi::Command::Winrm::Cmd

        # this is needed to get the unencoded string for noop and run debug
        alias :original_command_string :command_string

        def command_string
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
