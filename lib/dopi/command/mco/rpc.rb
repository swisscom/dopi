#
# DOPi Plugin: MCO RPC
#
require 'mcollective'

module Dopi
  class Command
    module Mco
      class Rpc < Dopi::Command
        include Dopi::ExitCodeParser
        include MCollective::RPC

        def validate
          log_validation_method('options_valid?', CommandParsingError)
          log_validation_method('arguments_valid?', CommandParsingError)
          log_validation_method('expect_exit_codes_valid?', CommandParsingError)
          # Skip validation in subclasses that overwrite the non optional methods
          unless Dopi::Command::Mco::Rpc > self.class && self.method(:agent).owner == self.class
            log_validation_method('agent_valid?', CommandParsingError)
          end
          unless Dopi::Command::Mco::Rpc > self.class && self.method(:action).owner == self.class
            log_validation_method('action_valid?', CommandParsingError)
          end
        end

        def run
          result_ok = true
          flags = {
            :configfile      => Dopi.configuration.mco_config,
            :options         => options,
            :exit_on_failure => false
          }
          mc = rpcclient(agent, flags)
          results = mc.custom_request(action, arguments, [@node.name], {'identity' => @node.name})
          if results.empty?
            Dopi.log.error(@node.name + ":" + name + " - No answer from node recieved")
            result_ok = false
          else
            result_ok = false unless parse_mco_result(results.first)
          end
          mc.disconnect
          result_ok
        end

        def agent
          @agent ||= agent_valid? ?
            hash[:agent] : nil
        end

        def options
          @options ||= options_valid? ?
            options_defaults.merge(hash[:options]) :
            options_defaults
        end

        def action
          @action ||= action_valid? ?
            hash[:action] : nil
        end

        def arguments
          @arguments ||= arguments_valid? ?
            hash[:arguments] : {}
        end

      private

        def expect_exit_codes_defaults
          0
        end

        def options_defaults
          MCollective::Util.default_options.merge({
            :config => Dopi.configuration.mco_config
          })
        end

        def parse_mco_result(result)
          result_ok = true
          unless check_exit_code(result[:statuscode])
            Dopi.log.error(@node.name + ":" + name + " - " + result[:statusmsg])
            result_ok = false
          end
          result_ok = false unless parse_mco_result_data(result[:data])
          result_ok
        end

        def parse_mco_result_data(data)
          warning  = "You are using the RPC plugin to run the #{agent} MCollective agent."
          warning += " DOPi will not know what to expect in the resulting data as this is plugin specific."
          warning += " Not all errors may be detected."
          Dopi.log.warn(warning)
          Dopi.log.info(data.inspect)
          return true
        end

        def agent_valid?
          hash[:agent] or
            raise CommandParsingError, "No agent defined"
          hash[:agent].kind_of?(String) or
            raise CommandParsingError, "The value for 'agent' has to be a String"
          begin
            MCollective::DDL.new(hash[:agent])
          rescue => e
            raise CommandParsingError, "Unable to load the MCollective agent #{hash[:agent]}on this system: #{e.message}"
          end
          true
        end

        def options_valid?
          return false if hash[:options].nil? # is optional
          hash[:options].kind_of?(Hash) or
            raise CommandParsingError, "The value for 'options' has to be a Hash"
        end

        def action_valid?
          hash[:action] or
           raise CommandParsingError, "No action defined"
          hash[:action].kind_of?(String) or
            raise CommandParsingError, "The value for 'action' has to be a String"
          agent_ddl = nil
          begin
            agent_ddl = MCollective::DDL.new(agent)
          rescue CommandParsingError
            raise CommandParsingError, "Agent not valid, unable to verify the action #{hash[:action]}"
          else
            agent_ddl.actions.include?(hash[:action]) or
              raise CommandParsingError, "The action #{hash[:action]} for agent #{agent} does not exist"
          end
          true
        end

        def arguments_valid?
          hash.nil? or hash[:arguments].nil? or hash[:arguments].kind_of?(Hash) or
            raise CommandParsingError, "The value for 'arguments' has to be a Hash" 
          begin
            args = hash ? ( hash[:arguments] or {} ) : {}
            agent_ddl = MCollective::DDL.new(agent)
            agent_ddl.validate_rpc_request(action, args)
          rescue CommandParsingError
            raise CommandParsingError, "Agent and/or Action not valid, unable to verify the action #{hash[:action]}"
          rescue MCollective::DDLValidationError => e
            raise CommandParsingError, "Error while parsing arguments for agent #{agent} and action #{action}: #{e.message}"
          end
          return false if hash[:arguments].nil? # is completely optional if no exception was raised so far
          true
        end

      end
    end
  end
end
