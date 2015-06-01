#
# DOPi Plugin: Wait For Login
#
# This DOPi Plugin will check if the specified file on
# the node exists
#
# Plugin Settings:
#
# file
# The file to check
# default: nil
#
require 'pathname'

module Dopi
  class Command
    class Ssh
      class FileExists < Dopi::Command::Ssh::Custom

        def exec
          "[ -e #{file} ]"
        end

        def file
          @file ||= file_valid? ?
            hash[:file] : nil
        end

        def validate
          super
          log_validation_method('file_valid?', CommandParsingError)
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

      end
    end
  end
end
