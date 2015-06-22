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
        log(:info, "Running dummy command")
        if @command_hash.class == Hash
          log(:info, "Command hash was: #{hash.inspect}")
        end
      end

    end
  end
end


