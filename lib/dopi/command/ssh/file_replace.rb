#
# DOPi Plugin: File Replace
#

module Dopi
  class Command
    class Ssh
      class FileReplace < Dopi::Command
        include Dopi::Connector::Ssh
        include Dopi::CommandParser::ExitCode

      public

        def validate
          validate_ssh
          validate_exit_code
          log_validation_method(:replacement_valid?, CommandParsingError)
          log_validation_method(:global_valid?, CommandParsingError)
        end

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = ssh_command({}, command_string)
          check_exit_code(cmd_exit_code)
        end

        def run_noop
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
        end

        def replacement
          @replacement ||= replacement_valid? ?
            hash[:replacement] : nil
        end

        def global
          @global ||= global_valid? ?
            hash[:global] : true
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
          "sed -i \"s/#{pattern}/#{replacement}/#{global_string}\" #{file}"
        end

        def global_string
          global ? 'g' : ''
        end

        def replacement_valid?
          hash[:replacement] or
            raise CommandParsingError, "Plugin #{name}: The key 'replacement' needs to be specified"
          hash[:replacement].kind_of?(String) or
            raise CommandParsingError, "Plugin #{name}: The value in 'replacement' has to be a String"
        end

        def global_valid?
          return false if hash[:global].nil? # is optional
          hash[:global].kind_of?(TrueClass) or hash[:global].kind_of?(FalseClass) or
            raise CommandParsingError, "Plugin #{name}: The value for 'global' must be boolean"
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
