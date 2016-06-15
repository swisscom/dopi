#
# This class loades the dopi command plugins
#
require 'dop_common'
require 'forwardable'
require 'timeout'


module Dopi
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
      @plugin_defaults[node_name].merge!(DopCommon::HashParser.symbolize_keys(hash))
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
      # make sure verify commands are initialized as well
      verify_commands
    end

    def merged_hash
      if @command_parser.hash.kind_of?(Hash)
        self.class.plugin_defaults(@node.name).merge(@command_parser.hash)
      else
        self.class.plugin_defaults(@node.name)
      end
    end

    def_delegator :@command_parser, :plugin, :name

    def meta_run(noop = false)
      return if skip_run?(noop)
      state_run unless noop
      Timeout::timeout(plugin_timeout) do
        log(:info, "Running command #{name}") unless @is_verify_command
        if noop
          run_noop
        else
          if run
            if verify_after_run
              verify_commands_ok? or
                raise CommandExecutionError, "Verify commands failed to confirm a successful run"
            end
            state_finish
            log(:info, "#{name} [OK]") if state_done?
          else
            state_fail
            log(:info, "#{name} [FAILED]")
          end
        end
      end
    rescue GracefulExit
      log(:info, "Command excited gracefuly, resetting to ready")
      state_reset(true) unless noop
    rescue Timeout::Error
      log(:error, "Command timed out (plugin_timeout is set to #{plugin_timeout})", false)
      state_fail unless noop
    rescue CommandExecutionError => e
      log(:error, "Command failed: #{e.message}", false)
      Dopi.log.error(e) if Dopi.configuration.trace
      state_fail unless noop
    rescue => e
      log(:error, "Unexpected error!!! This is a Bug", false)
      Dopi.log.error(e.message)
      Dopi.log.error(e.backtrace)
      state_fail unless noop
      raise e
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
    def_delegators :@command_parser, :plugin_timeout, :verify_after_run

    def run
      raise Dopi::CommandExecutionError, "No run method implemented in plugin #{name}"
    end

    def run_noop
      Dopi.log.error("The plugin #{name} does not support noop runs and will not show the command")
    end

    def validate
      Dopi.log.warn("No 'validate' method implemented in plugin #{name}. Validation not possible")
      true
    end

    def skip_run?(noop = false)
      if state_done?
        log(:info, "Is already in state 'done'. Skipping")
        true
      elsif verify_commands.any? && verify_commands_ok?
        if noop
          log(:info, "All verify commands ok. Skipping")
        else
          log(:info, "All verify commands ok. Skipping and marked as 'done'")
          state_run
          state_finish
        end
        true
      else
        false
      end
    end

    def verify_commands
      @verify_commands ||= parsed_verify_commands.map do |command|
        Dopi::Command.create_plugin_instance(command, @step, @node, true)
      end
    end

    def verify_commands_ok?
      verify_commands.all? do |command|
        command.state_reset(true)
        command.meta_run
        command.state_done?
      end
    end

    def log_prefix
      if @is_verify_command
        "  [Verify] #{@node.name} : "
      else
        "  [Command] #{@node.name} : "
      end
    end

    def log(severity, message, overwrite = true)
      # Ignore verify command errors, because they are expected
      if @is_verify_command && overwrite
        severity = :debug if severity == :error || severity == :warn
      end
      # TODO: implement Node specific logging
      # for now we simply forward to the global DOPi logger
      Dopi.log.log(Logger.const_get(severity.upcase), log_prefix + message)
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
require 'dopi/command/ssh/file_deploy'
require 'dopi/command/ssh/reboot'
require 'dopi/command/mco/rpc'
require 'dopi/command/winrm/cmd'
require 'dopi/command/winrm/powershell'
require 'dopi/command/winrm/wait_for_login'
require 'dopi/command/winrm/file_contains'
require 'dopi/command/winrm/file_exists'

# TODO: load plugins from the plugin paths
