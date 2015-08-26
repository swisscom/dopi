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

  class CommandConnectionError < StandardError
  end

  class Command
    extend Forwardable
    include Dopi::State
    include DopCommon::Validator

    def self.inherited(klass)
      PluginManager << klass
    end

    def self.create_plugin_instance(command_parser, step, node, is_verify_command = false)
      plugin_type = PluginManager.get_plugin_name(self) + '/'
      plugin_full_name = plugin_type + command_parser.plugin
      Dopi.log.debug("Creating instance of plugin #{plugin_full_name}")
      PluginManager.create_instance(plugin_full_name, command_parser, step, node, is_verify_command)
    end

    def self.set_plugin_defaults(node_name, hash)
      @plugin_defaults ||= {}
      @plugin_defaults[node_name] ||= {}
      @plugin_defaults[node_name].merge!(hash)
    end

    def self.plugin_defaults(node_name)
      @plugin_defaults ||= {}
      @plugin_defaults[node_name] ||= {}
    end

    # wipe all the defaults for this plugin
    def self.wipe_plugin_defaults
      @plugin_defaults = {}
    end

    # delete all the defaults on this plugin for the node
    def self.delete_plugin_defaults(node_name)
      @plugin_defaults ||= {}
      @plugin_defaults[node_name] = {}
    end

    # delete a specific default for the node
    def self.delete_plugin_default(node_name, key)
      @plugin_defaults ||= {}
      @plugin_defaults[node_name] ||= {}
      @plugin_defaults[node_name].delete(key)
    end


    attr_reader :node, :hash, :is_verify_command

    def initialize(command_parser, step, node, is_verify_command)
      @command_parser    = command_parser
      @step              = step
      @node              = node
      @is_verify_command = is_verify_command
      @hash              = merged_hash
      log(:debug, "Plugin created with merged command hash: #{hash.inspect}")
    end

    def merged_hash
      if @command_parser.hash.kind_of?(Hash)
        self.class.plugin_defaults(@node.name).merge(@command_parser.hash)
      else
        self.class.plugin_defaults(@node.name)
      end
    end

    def_delegator :@command_parser, :plugin, :name

    def meta_run
      if state_done?
        log(:info, "Command '#{name}' is in state 'done'. Skipping")
        return
      end
      state_run
      verify_commands.each do |verify_command|
        verify_command.state_reset if verify_command.state_failed?
        # TODO: Reset done state as well. We should always rerun validation commands
      end
      begin
        Timeout::timeout(plugin_timeout) do
          if state_running? && verify_commands.any?
            state_finish if verify_commands.all? do |command| 
              command.meta_run
              command.state_done?
            end
          end
          if state_running?
            log(:info, "Running command")
            run ? state_finish : state_fail
            log(:info, "Done") if state_done?
          else
            log(:info, "Nothing to do for command")
          end
        end
      rescue Timeout::Error
        state_fail
        log(:error, "Command timed out (plugin_timeout is set to #{plugin_timeout})")
      rescue => e
        state_fail
        log(:error, "Command failed")
        raise e
      end
    end

    def meta_valid?
      validity = valid?
      validity = false unless verify_commands.all? do |verify_command|
        begin
          verify_command.meta_valid?
        rescue PluginLoaderError => e
          Dopi.log.error("Step '#{@step.name}': Can't load plugin #{verify_command.plugin}: #{e.message}")
        end
      end
      validity
    end

  private

    def_delegator  :@command_parser, :verify_commands, :parsed_verify_commands
    def_delegators :@command_parser, :plugin_timeout

    def run
      raise Dopi::CommandExecutionError, "No run method implemented in plugin #{name}"
    end

    def validate
      Dopi.log.warn("No 'validate' method implemented in plugin #{name}. Validation not possible")
      true
    end

    def verify_commands
      @verify_commands ||= parsed_verify_commands.map do |command|
        Dopi::Command.create_plugin_instance(command, @step, @node, true)
      end
    end

    def log(severity, message)
      # Ignore verify command errors, because they are expected
      if @is_verify_command
        severity = :debug
      end
      # TODO: implement Node specific logging
      # for now we simply forward to the global DOPi logger
      enriched_message = "  Step '#{@step.name}', Node '#{@node.name}', Plugin '#{name}' : " + message
      Dopi.log.log(Logger.const_get(severity.upcase), enriched_message)
    end

  end
end


# load standard command plugins
require 'dopi/command/dummy'
require 'dopi/command/custom'
require 'dopi/command/ssh/custom'
require 'dopi/command/ssh/puppet_agent_run'
require 'dopi/command/ssh/wait_for_login'
require 'dopi/command/ssh/file_contains'
require 'dopi/command/ssh/file_exists'
require 'dopi/command/ssh/file_replace'
require 'dopi/command/mco/rpc'
require 'dopi/command/winrm'
require 'dopi/command/winrm/cmd'

# TODO: load plugins from the plugin paths
