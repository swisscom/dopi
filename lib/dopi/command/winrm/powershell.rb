module Dopi
  class Command
    class Winrm
      class Powershell < Dopi::Command::Winrm::Cmd

        def exec
          script = WinRM::PowershellScript.new(super)
          "powershell -encodedCommand #{script.encoded()}"
        end

      end
    end
  end
end
