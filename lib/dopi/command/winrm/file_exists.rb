#
# DOPi Plugin: File Exists
#
require 'pathname'

module Dopi
  class Command
    class Winrm
      class FileExists < Dopi::Command
        include Dopi::Connector::Winrm
        include Dopi::CommandParser::ExitCode

        def validate
          validate_winrm
          validate_exit_code
          log_validation_method(:file_valid?, CommandParsingError)
        end

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = winrm_powershell_command(command_string)
          check_exit_code(cmd_exit_code)
        end

        def run_noop
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
        end

        def command_string
          "if(-not(Test-Path '#{file}')) { exit 1 }"
        end

        def file
          @file ||= file_valid? ?
            hash[:file] : nil
        end

        def file_valid?
          hash[:file] or
            raise CommandParsingError, "Plugin #{name}: The key 'file' needs to be specified"
          begin
            hash[:file][/[a-zA-Z]+:\\/] or hash[:file][/\\\\\w+/] or
              raise CommandParsingError, "Plugin #{name}: The path for 'file' has to be absolute"
          rescue ArgumentError => e
            raise CommandParsingError, "Plugin #{name}: The value in 'file' is not a valid file path: #{e.message}"
          end
        end

      end
    end
  end
end
