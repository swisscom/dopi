#
# SSH custom command
#
module Dopi
  class Command
    class Ssh
      class PuppetAgentRun < Dopi::Command::Ssh::Custom

        def exec
          'puppet agent --test'
        end

        def expect_exit_codes_defaults
          [ 0, 2 ]
        end

      end
    end
  end
end
