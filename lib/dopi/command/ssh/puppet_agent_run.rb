#
# SSH custom command
#
module Dopi
  class Command
    class Ssh
      class PuppetAgentRun < Dopi::Command
        include Dopi::Connector::Ssh
        include Dopi::CommandParser::PuppetRun

      public
        def validate
          validate_ssh
          validate_puppet_run
        end

        def initialize(command_parser, step, node, is_verify_command)
          command_parser.overwrite_defaults = { :plugin_timeout => 1800 }
          super(command_parser, step, node, is_verify_command)
        end

        def puppet_bin
          '/usr/bin/puppet'
        end

        def check_run_lock
          ssh_command(env, "test -f $(#{puppet_bin} config print statedir)/agent_catalog_run.lock")
        end

        def puppet_run
          ssh_command(env, "#{puppet_bin} agent --test --color false #{arguments}")
        end

      private

      end
    end
  end
end
