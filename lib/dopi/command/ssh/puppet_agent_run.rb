#
# SSH custom command
#
module Dopi
  class Command
    class Ssh
      class PuppetAgentRun < Dopi::Command
        include Dopi::Connector::Ssh
        include Dopi::CommandParser::Env
        include Dopi::CommandParser::Arguments
        include Dopi::CommandParser::ExitCode
        include Dopi::CommandParser::Output

      public

        def initialize(command_parser, step, node, is_verify_command)
          command_parser.overwrite_defaults = { :plugin_timeout => 1800 }
          super(command_parser, step, node, is_verify_command)
        end

        def validate
          validate_ssh
          validate_env
          validate_arguments
          validate_exit_code
          validate_output
        end

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = ssh_command(env, command_string)
          check_output(cmd_stdout) &&
            check_output(cmd_stderr) &&
            check_exit_code(cmd_exit_code)
        end

        def run_noop
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
        end

        def expect_exit_codes_defaults
          [ 0, 2 ]
        end

        def parse_output_defaults
          { :error => [
              '^Error:'
            ],
            :warning => [
              '^Warning:'
            ]
          }
        end

      private

        def command_string
          "puppet agent --test --color false #{arguments}"
        end

      end
    end
  end
end
