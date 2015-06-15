#
# DOPi Plugin: MCO RPC
#
# This DOPi Plugin will call an action on an mco agent
#
# Plugin Settings:
#
#
require 'mcollective'

module Dopi
  class Command
    module Mco
      class Rpc < Dopi::Command
        include Dopi::ExitCodeParser
        include MCollective::RPC

        def validate
          log_validation_method('agent_valid?', CommandParsingError)
          log_validation_method('options_valid?', CommandParsingError)
          log_validation_method('action_valid?', CommandParsingError)
          log_validation_method('arguments_valid?', CommandParsingError)
          log_validation_method('expect_exit_codes_valid?', CommandParsingError)
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
            MCollective::Util.default_options.merge(hash[:options]) :
            MCollective::Util.default_options
        end

        def action
          hash[:action] #TODO: implement
        end

        def arguments
          hash[:arguments] #TODO: implement
        end

      private

        def expect_exit_codes_defaults
          0
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
          true #TODO: implement
        end

        def action_valid?
          # mc = MCollective::RPC::rpcclient(agent)
          # mc.actions.include?(hash[:action]
          true #TODO: implement
        end

        def arguments_valid?
          true #TODO: implement
        end

      end
    end
  end
end
