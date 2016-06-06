#
# DOPi Plugin: File Contains
#
require 'pathname'

module Dopi
  class Command
    class Ssh
      class FileContains < Dopi::Command
        include Dopi::Connector::Ssh
        include Dopi::CommandParser::ExitCode

      public

        def validate
          validate_ssh
          validate_exit_code
          log_validation_method(:file_valid?, CommandParsingError)
          log_validation_method(:pattern_valid?, CommandParsingError)
        end

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = ssh_command({}, command_string)
          check_exit_code(cmd_exit_code)
        end

        def run_noop
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
        end

        def file
          @file ||= file_valid? ? hash[:file] : nil
        end

        def pattern
          @pattern ||= pattern_valid? ?
            hash[:pattern] : nil
        end

      private

        def command_string
          "grep -e \"#{pattern}\" #{file}"
        end

        def file_valid?
          hash[:file] or
            raise CommandParsingError, "Plugin #{name}: The key 'file' needs to be specified"
          begin
            Pathname.new(hash[:file]).absolute? or
              raise CommandParsingError, "Plugin #{name}: The path for 'file' has to be absolute"
          rescue ArgumentError => e
            raise CommandParsingError, "Plugin #{name}: The value in 'file' is not a valid file path: #{e.message}"
          end
        end

        def pattern_valid?
          hash[:pattern] or
            raise CommandParsingError, "Plugin #{name}: The key 'pattern' needs to be specified"
          begin
            Regexp.new(hash[:pattern])
          rescue
            raise CommandParsingError, "Plugin #{name}: The value in 'pattern' is not a valid regexp: #{e.message}"
          end
        end

      end
    end
  end
end
