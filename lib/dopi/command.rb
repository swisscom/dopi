#
# This class loades the dopi command plugins
#
require 'timeout'


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

    def default_plugin_timeout
      300
    end

    # TODO: Use dop_common validation helper here as soon
    # as it is implemented
    def parse_plugin_timeout
      @command_hash['plugin_timeout'].class == Fixnum ?
        @command_hash['plugin_timeout'] : default_plugin_timeout
    end

    def plugin_timeout
      @plugin_timeout ||= parse_plugin_timeout
    end

    def verify_commands
      Dopi.log.warning('Verify command parsing is not implemented yet') if @command_hash['verify_commands']
      @verify_commands ||= []
    end

    def meta_run
      state_run
      Dopi.log.debug("Running command #{@name} on #{@node.fqdn}")
      begin
        Timeout::timeout(plugin_timeout) do
          if state_running? && verify_commands.any?
            state_finish if verify_commands.all? {|command| command.meta_run}
          end
          if state_running?
            run ? state_finish : state_fail
          else
            Dopi.log.info("Nothing to do for command #{@name} on #{@node.fqdn}")
          end
        end
      rescue Timeout::Error
        state_fail
        Dopi.log.error("Command #{@name} timed out on #{@node.fqdn}")
      rescue Exception => e
        state_fail
        raise e
      end
    end

    def run
      raise Dopi::CommandExecutionError, "No run method implemented in plugin #{@name}"
    end

  end
end


# load standard command plugins
require 'dopi/command/dummy'
require 'dopi/command/custom'
require 'dopi/command/ssh/custom'
require 'dopi/command/ssh/puppet_agent_run'
require 'dopi/command/ssh/wait_for_login'

# TODO: load plugins from the plugin paths
