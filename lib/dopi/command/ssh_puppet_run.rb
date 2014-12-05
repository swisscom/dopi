#
# SSH custom command
#

module Dopi
  class Command

    class SshPuppetRun < Dopi::Command::SshCustom

      def exec
        'puppet agent --test'
      end

    end

  end
end
