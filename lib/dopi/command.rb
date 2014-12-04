#
# This class loades the dopi command plugins
#

module Dopi
  class Command

    def self.inherited(klass)
      PluginManager << klass
    end

    def self.create_plugin_instance(plugin_name, node, command_hash)
      plugin_type = PluginManager.get_plugin_name(self) + '/'
      Dopi.log.debug("Creating instance of plugin #{plugin_type + plugin_name}")
      PluginManager.create_instance(plugin_type + plugin_name, node, command_hash)
    end

  end
end


# load standard command plugins
require 'dopi/command/custom'
require 'dopi/command/ssh_custom'

# TODO: load plugins from the plugin paths
