#
# DOPi Plugin: File Contains
#

module Dopi
  class Command
    class Winrm
      class FileContains < Dopi::Command
        include Dopi::Connector::Winrm
        include Dopi::CommandParser::ExitCode

        def validate
          validate_winrm
          validate_exit_code
          log_validation_method('file_valid?', CommandParsingError)
          log_validation_method('pattern_valid?', CommandParsingError)
        end

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = winrm_powershell_command(command_string)
          check_exit_code(cmd_exit_code)
        end

        def run_noop
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
        end

        def command_string
          "if(-not(Select-String -Pattern #{pattern} -Path '#{file}' -Quiet)) { exit 1 }"
        end

        def file
          @file ||= file_valid? ?
            hash[:file] : nil
        end

        def pattern
          @pattern ||= pattern_valid? ?
            hash[:pattern] : nil
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
