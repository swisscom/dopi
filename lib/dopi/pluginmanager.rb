#
# This class registers the plugins as they get loaded by ruby
# and can create instances based on the plugin name
#

module Dopi
  class PluginLoaderError < StandardError
  end

  module PluginManager

    @plugins = {}

    def self.<<(plugin_klass)
      plugin_name = get_plugin_name(plugin_klass)

      raise Dopi::PluginLoaderError,
        "Plugin class #{plugin_klass.to_s} (#{plugin_name}) already loaded" if @plugins[plugin_name]

      @plugins[plugin_name] = plugin_klass
      Dopi.log.debug("Registering Plugin #{plugin_name} with class #{plugin_klass}")
    end

    def self.create_instance(plugin_name, *args)
      begin
        @plugins[plugin_name].new(*args)
      rescue Exception => e
        raise PluginLoaderError, "Could not create instance of plugin #{plugin_name}: #{e.message}"
      end
    end

    def self.get_plugin_name(plugin_klass)
      plugin_klass.to_s.
        gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
    
  end
end
