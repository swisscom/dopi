#
# This is a mixin for command plugins that need to parse puppet_run specific
# options and for some methods to wrap the rerun logic.
#
require 'pathname'

module Dopi
  module CommandParser
    module PuppetRun
      include Dopi::CommandParser::Env
      include Dopi::CommandParser::Arguments
      include Dopi::CommandParser::Output

    public

      def validate_puppet_run
        validate_env
        validate_arguments
        validate_output
        log_validation_method('rerun_on_change_valid?', CommandParsingError)
        log_validation_method('rerun_on_error_valid?', CommandParsingError)
        log_validation_method('max_rerun_valid?', CommandParsingError)
        log_validation_method('wait_if_already_running_valid?', CommandParsingError)
        log_validation_method('puppet_bin_valid?', CommandParsingError)
      end

      def rerun_on_change
        @rerun_on_change ||= rerun_on_change_valid? ? hash[:rerun_on_change] : false
      end

      def rerun_on_error
        @rerun_on_error ||= rerun_on_error_valid? ? hash[:rerun_on_error] : false
      end

      def max_rerun
        @max_rerun ||= max_rerun_valid? ? hash[:max_rerun] : 1
      end

      def wait_if_already_running
        @wait_if_already_running ||= wait_if_already_running_valid? ? hash[:wait_if_already_running] : true
      end

      def puppet_bin
        @puppet_bin ||= puppet_bin_valid? ? hash[:puppet_bin] : 'puppet'
      end

      def run
        runs = 0
        loop do
          raise GracefulExit if signals[:stop]
          if check_run_lock_wrapper
            if wait_if_already_running
              log(:info, "Puppet run already in progress, waiting 10s to check again if finished")
              sleep(10)
            else
              log(:error, "Puppet run already in progress and wait_if_already_running = false")
              return false
            end
          else
            runs += 1
            if runs < 2
              log(:info, "Starting Puppet Run")
            else
              log(:info, "Starting Puppet Rerun #{runs - 1} of #{max_rerun}")
            end
            case puppet_run_wrapper
            when :done then return true
            when :change
              if rerun_on_change
                if runs < 2
                  log(:info, "Puppet had changes and rerun_on_change = true")
                else
                  log(:warn, "Puppet had still changes after multiple reruns. Please fix your Puppet manifests")
                end
                return true if max_rerun < runs
              else
                return true
              end
            else
              if rerun_on_error
                log(:warn, "Puppet had ERRORS during the run and rerun_on_errors = true. Please fix your Puppet manifests")
                if max_rerun < runs
                  log(:error, "Puppet had ERRORS during the run! max_reruns (#{max_rerun}) reached!")
                  return false
                end
              else
                return false
              end
            end
          end
        end
      end

      def check_run_lock_wrapper
        cmd_stdout, cmd_stderr, cmd_exitcode = check_run_lock
        return true if cmd_exitcode == 0
        return false
      end

      # puppet run wrapper method
      # this will return :done, :change or :error
      def puppet_run_wrapper
        cmd_stdout, cmd_stderr, cmd_exitcode = puppet_run
        return :error   unless (check_output(cmd_stdout) && check_output(cmd_stderr))
        case cmd_exitcode
        when 0 then return :done
        when 2 then return :change
        else return :error
        end
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

      def rerun_on_change_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:rerun_on_change].nil? # is optional
        hash[:rerun_on_change].kind_of?(TrueClass) or hash[:rerun_on_change].kind_of?(FalseClass) or
          raise CommandParsingError, "Plugin #{name}: The value for 'rerun_on_change' must be boolean"
      end

      def rerun_on_error_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:rerun_on_error].nil? # is optional
        hash[:rerun_on_error].kind_of?(TrueClass) or hash[:rerun_on_error].kind_of?(FalseClass) or
          raise CommandParsingError, "Plugin #{name}: The value for 'rerun_on_error' must be boolean"
      end

      def max_rerun_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:max_rerun].nil? # is optional
        hash[:max_rerun].kind_of?(Fixnum) or
          raise CommandParsingError, "Plugin #{name}: The value for 'max_rerun' has to be a number"
        hash[:max_rerun] > 0 or
          raise CommandParsingError, "Plugin #{name}: The value for 'max_rerun' has to be > 0"
      end

      def wait_if_already_running_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:wait_if_already_running].nil? # is optional
        hash[:wait_if_already_running].kind_of?(TrueClass) or hash[:wait_if_already_running].kind_of?(FalseClass) or
          raise CommandParsingError, "Plugin #{name}: The value for 'wait_if_already_running' must be boolean"
      end

      def puppet_bin_valid?
        return false unless hash.kind_of?(Hash)
        return false if hash[:puppet_bin].nil? # is optional
        begin
          Pathname.new(hash[:puppet_bin]).absolute? or hash[:puppet_bin][/[a-zA-Z]+:\\/] or hash[:puppet_bin][/\\\\\w+/] or
            raise CommandParsingError, "Plugin #{name}: The path for 'puppet_bin' has to be absolute"
        rescue ArgumentError => e
          raise CommandParsingError, "Plugin #{name}: The value in 'puppet_bin' is not a valid file path: #{e.message}"
        end
      end

    end
  end
end
