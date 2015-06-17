#
# DOPi Plugin: File Contains
#
require 'pathname'

module Dopi
  class Command
    class Ssh
      class FileContains < Dopi::Command::Ssh::Custom

        def exec
          "grep -e \"#{pattern}\" #{file}"
        end

        def file
          @file ||= file_valid? ?
            hash[:file] : nil
        end

        def pattern
          @pattern ||= pattern_valid? ?
            hash[:pattern] : nil 
        end

        def validate
          super
          log_validation_method('file_valid?', CommandParsingError)
          log_validation_method('pattern_valid?', CommandParsingError)
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
