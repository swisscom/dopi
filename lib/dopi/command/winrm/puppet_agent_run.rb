#
# SSH custom command
#
module Dopi
  class Command
    class Winrm
      class PuppetAgentRun < Dopi::Command
        include Dopi::Connector::Winrm
        include Dopi::CommandParser::PuppetRun

      public
        def validate
          validate_winrm
          validate_puppet_run
        end

        def initialize(command_parser, step, node, is_verify_command)
          command_parser.overwrite_defaults = { :plugin_timeout => 1800 }
          super(command_parser, step, node, is_verify_command)
        end

        def puppet_bin
          'puppet'
        end

        def check_run_lock_b
          false
        end

        def check_run_lock
          winrm_powershell_command <<-cmd
            $Statedir = #{puppet_bin} config print statedir
            if(-not( Test-Path "$Statedir/agent_catalog_run.lock" )) { exit 1 }
          cmd
        end

        def puppet_run
          winrm_powershell_command("#{puppet_bin} agent --test --color false #{arguments}")
        end

      private

      end
    end
  end
end
