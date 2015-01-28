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

      end
    end
  end
end
