#
# DOPi Plugin: Deploy File
#
require 'pathname'
require "base64"

module Dopi
  class Command
    class Ssh
      class FileDeploy < Dopi::Command
        include DopCommon::HashParser
        include Dopi::Connector::Ssh
        include Dopi::CommandParser::ExitCode

      public

        def validate
          validate_ssh
          validate_exit_code
          log_validation_method('file_valid?', CommandParsingError)
          log_validation_method('content_valid?', CommandParsingError)
        end

        def run
          cmd_stdout, cmd_stderr, cmd_exit_code = ssh_command({}, command_string)
          check_exit_code(cmd_exit_code)
        end

        def run_noop
          log(:info, "(NOOP) Executing '#{command_string}' for command #{name}")
        end

        def file
          file_valid? ? hash[:file] : nil
        end

        def content
          content_valid? ? load_content(hash[:content]) : nil
        end

      private

        def command_string
          "echo -n #{Base64.strict_encode64(content)} | base64 -d > #{file}"
        end

        def file_valid?
          hash[:file] or
            raise CommandParsingError, "Plugin #{name}: The key 'file' needs to be specified"
          hash[:file].kind_of?(String) or
            raise CommandParsingError, "Plugin #{name}: The value for key 'file' has to be a String"
          begin
            Pathname.new(hash[:file]).absolute? or
              raise CommandParsingError, "Plugin #{name}: The path for 'file' has to be absolute"
          rescue ArgumentError => e
            raise CommandParsingError, "Plugin #{name}: The value in 'file' is not a valid file path: #{e.message}"
          end
        end

        def content_valid?
          hash[:content] or
            raise CommandParsingError, "Plugin #{name}: The key 'content' needs to be specified"
          load_content_valid?(hash[:content])
        rescue DopCommon::PlanParsingError => e
          raise CommandParsingError, "Plugin #{name}: value content not valid: #{e.message}"
        end

      end
    end
  end
end
