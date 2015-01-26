#
# This class loades the dopi command plugins
#

module Dopi
  class CommandParsingError < StandardError
  end

  class CommandExecutionError < StandardError
  end

  class Command
    include Dopi::State

    def self.inherited(klass)
      PluginManager << klass
    end

    def self.create_plugin_instance(plugin_name, node, command_hash)
      plugin_type = PluginManager.get_plugin_name(self) + '/'
      Dopi.log.debug("Creating instance of plugin #{plugin_type + plugin_name}")
      PluginManager.create_instance(plugin_type + plugin_name, node, command_hash)
    end

    def initialize(plugin_name, node, command_hash = {})
      @name         = plugin_name.split('/').last
      @node         = node
      @command_hash = command_hash
    end

    def meta_run
      state_run
      Dopi.log.debug("Running command #{@name} on #{@node.fqdn}")
      begin
        run
      rescue Exception => e
        state_fail
        raise e
      end
      state_finish unless state_failed?
    end

    def run
      raise Dopi::CommandExecutionError, "No run method implemented in plugin #{@name}"
    end

  end
end


# load standard command plugins
require 'dopi/command/dummy'
require 'dopi/command/custom'
require 'dopi/command/ssh_custom'
require 'dopi/command/ssh_puppet_run'

# TODO: load plugins from the plugin paths
