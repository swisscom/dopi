#
# DOPi dummy command.
#
# this simply prints the command hash if there was one given
#

module Dopi
  class Command
    class Dummy < Dopi::Command

      def validate
        true
      end

      def run
        Dopi.log.info("running dummy command for node: #{node.name}")
        if @command_hash.class == Hash
          Dopi.log.info("command hash was: #{hash.inspect}")
        end
      end

    end
  end
end


