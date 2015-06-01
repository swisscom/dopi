#
# This class loades the dopi command plugins
#
require 'dop_common'
require 'forwardable'
require 'timeout'


module Dopi
  class CommandParsingError < StandardError
  end

  class CommandExecutionError < StandardError
  end

  class Command
    extend Forwardable
    include Dopi::State
    include DopCommon::Validator

    def self.inherited(klass)
      PluginManager << klass
    end

    def self.create_plugin_instance(plugin_name, node, command_parser)
      plugin_type = PluginManager.get_plugin_name(self) + '/'
      Dopi.log.debug("Creating instance of plugin #{plugin_type + plugin_name}")
      PluginManager.create_instance(plugin_type + plugin_name, node, command_parser)
    end

    attr_reader :node

    def initialize(node, command_parser)
      @node           = node
      @command_parser = command_parser
    end

    def_delegator :@command_parser, :plugin, :name

    def meta_run
      if state_done?
        Dopi.log.info("Command #{name} on node #{@node.name} is in state 'done'. Skipping")
        return
      end
      state_run
      Dopi.log.debug("Running command #{name} on #{@node.name}")
      begin
        Timeout::timeout(plugin_timeout) do
          if state_running? && verify_commands.any?
            state_finish if verify_commands.all? do |command| 
              command.meta_run
              command.state_done?
            end
          end
          if state_running?
            run ? state_finish : state_fail
          else
            Dopi.log.info("Nothing to do for command #{name} on #{@node.name}")
          end
        end
      rescue Timeout::Error
        state_fail
        Dopi.log.error("Command #{name} timed out on #{@node.name}")
      rescue Exception => e
        state_fail
        raise e
      end
    end

    def meta_valid?(step_name)
      validity = valid?
      validity = false unless verify_commands.all? do |verify_command|
        begin
          verify_command.meta_valid?(step_name)
        rescue PluginLoaderError => e
          Dopi.log.error("Step #{step_name}: Can't load plugin #{verify_command.plugin}: #{e.message}")
        end
      end
      validity
    end

  private

    def_delegator  :@command_parser, :verify_commands, :parsed_verify_commands
    def_delegators :@command_parser, :hash, :plugin_timeout

    def run
      raise Dopi::CommandExecutionError, "No run method implemented in plugin #{name}"
    end

    def validate
      Dopi.log.warn("No 'validate' method implemented in plugin #{name}. Validation not possible")
      true
    end

    def verify_commands
      @verify_commands ||= parsed_verify_commands.map do |command|
        Dopi::Command.create_plugin_instance(command.plugin, @node, command)
      end
    end

  end
end


# load standard command plugins
require 'dopi/command/dummy'
require 'dopi/command/custom'
require 'dopi/command/ssh/custom'
require 'dopi/command/ssh/puppet_agent_run'
require 'dopi/command/ssh/wait_for_login'
require 'dopi/command/ssh/file_exists'
require 'dopi/command/ssh/file_contains'

# TODO: load plugins from the plugin paths
