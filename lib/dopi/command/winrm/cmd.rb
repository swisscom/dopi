#
# DOPi Plugin: WinRM Command
#
require 'winrm'

module Dopi
  class Command
    class Winrm
      class Cmd < Dopi::Command::Winrm
        include Dopi::ExitCodeParser
        include Dopi::OutputParser

        def validate
          super
          log_validation_method('arguments_valid?', CommandParsingError)
          # Skip validation in subclasses that overwrite the non optional methods
          unless Dopi::Command::Winrm::Cmd > self.class && self.method(:exec).owner == self.class
            log_validation_method('exec_valid?', CommandParsingError)
          end
          log_validation_method('expect_exit_codes_valid?', CommandParsingError)
          validate_output_parser
        end

        def run
          result = []
          cmd_stdout, cmd_stderr, cmd_exit_code = run_command
          result << check_output(cmd_stdout)
          result << check_output(cmd_stderr)
          result << check_exit_code(cmd_exit_code)
          result.all?
        end

        def run_command
          cmd_stdout = ""
          result = winrm.cmd(exec) do |stdout, stderr|
            unless stdout.nil? or stdout.empty?
              cmd_stdout << stdout
              log(:debug, stdout)
            end
            unless stderr.nil? or stderr.empty?
              cmd_stderr << stderr
              log(:error, stderr)
            end
          end
          [cmd_stdout, cmd_stdout, result[:exitcode]]
        end

        def exec
          exec_valid? ? hash[:exec] : nil
        end

        def arguments
          arguments_valid? ? parse_arguments : ""
        end

      private

        def exec_valid?
          hash[:exec] or
            raise CommandParsingError, "No command to execute in 'exec' defined"
          hash[:exec].kind_of?(String) or
            raise CommandParsingError, "The value for 'exec' has to be a String"
        end

        def arguments_valid?
          return false unless hash.kind_of?(Hash) # plugin may not have parameters
          return false if hash[:arguments].nil? # arguments are optional
          hash[:arguments].kind_of?(Hash) or
            hash[:arguments].kind_of?(Array) or
            hash[:arguments].kind_of?(String) or
            raise CommandParsingError, "The value for 'arguments' hast to be an Array, Hash or String"
        end

        def parse_arguments
          case hash[:arguments]
          when Hash   then hash[:arguments].to_a.flatten.join(' ')
          when Array  then hash[:arguments].flatten.join(' ')
          when String then hash[:arguments]
          else ""
          end
        end

        def expect_exit_codes_defaults
          0
        end

        def parse_output_defaults
          nil
        end

      end
    end
  end
end