#
# Step
#
require 'forwardable'
require 'parallel'

module Dopi
  class Step
    extend Forwardable
    include Dopi::State

    DEFAULT_MAX_IN_FLIGHT = 3

    attr_accessor :plan

    def initialize(step_parser, plan, nodes = [])
      @step_parser = step_parser
      @plan        = plan
      @nodes       = nodes

      commands.each{|command| state_add_child(command)}
    end

    def_delegators :@step_parser, :name

    def run(run_for_nodes, noop = false)
      if state_done?
        Dopi.log.info("Step '#{name}' is in state 'done'. Skipping")
        return
      end
      Dopi.log.info("Starting to run step '#{name}'")
      run_commands(run_for_nodes, noop)
      Dopi.log.info("Step '#{name}' successfully finished.") if state_done?
      Dopi.log.error("Step '#{name}' failed! Stopping execution.") if state_failed?
    end

    def delete_plugin_defaults
      if @step_parser.delete_plugin_defaults == :all
        # Wipe all the defaults
        PluginManager.plugin_klass_list('^dopi/command/').each do |plugin_klass|
          @nodes.each{|node| plugin_klass.delete_plugin_defaults(node.name)}
        end
      else
        @step_parser.delete_plugin_defaults.each do |entry|
          plugin_list(entry[:plugins]).each do |plugin_klass|
            if entry[:delete_keys] == :all
              @nodes.each{|node| plugin_klass.delete_plugin_defaults(node.name)}
            else
              entry[:delete_keys].each do |key|
                @nodes.each{|node| plugin_klass.delete_plugin_default(node.name, key)}
              end
            end
          end
        end
      end
    end

    def set_plugin_defaults
      @step_parser.set_plugin_defaults.each do |entry|
        defaults_hash = entry.dup
        defaults_hash.delete(:plugins)
        plugin_list(entry[:plugins]).each do |plugin_klass|
          @nodes.each{|node| plugin_klass.set_plugin_defaults(node.name, defaults_hash)}
        end
      end
    end

    def plugin_list(plugin_filter_list)
      if plugin_filter_list == :all
        PluginManager.plugin_klass_list('^dopi/command/')
      else
        all_plugin_names = PluginManager.plugin_name_list('^dopi/command/').map{|p| p.sub('dopi/command/', '')}
        selected_plugin_names = plugin_filter_list.map do |filter|
          case filter
          when Regexp then all_plugin_names.select{|p| p =~ filter}
          else all_plugin_names.select{|p| p == filter}
          end
        end
        selected_plugin_names.flatten.uniq.map{|p| PluginManager.plugin_klass('dopi/command/' + p)}
      end
    end

    def run_commands(run_for_nodes, noop)
      commands_copy = commands.select{|n| run_for_nodes.include?(n.node)}
      if canary_host
        pick = rand(commands_copy.length - 1)
        commands_copy.delete_at(pick).meta_run(noop)
      end
      unless state_failed?
        number_of_threads = max_in_flight == -1 ? commands_copy.length : max_in_flight
        Parallel.each(commands_copy, :in_threads => number_of_threads) do |command|
          Dopi::ContextLoggers.log_context = command.node.name
          raise Parallel::Break if state_failed?
          if signals[:stop]
            Dopi.log.warn("Step '#{name}': Stopping thread spawning")
            raise Parallel::Break
          end
          command.meta_run(noop)
        end
      end
    end

    def max_in_flight
      @max_in_flight ||= @step_parser.max_in_flight || @plan.max_in_flight || DEFAULT_MAX_IN_FLIGHT
    end

    def canary_host
      @canary_host ||= @step_parser.canary_host || @plan.canary_host
    end

    def valid?
      if @nodes.empty?
        Dopi.log.error("Step '#{name}': Nodes list is empty")
        return false
      end
      command_plugin_valid?
    end

    def command_plugin_valid?
      begin
        commands.first.meta_valid?
      rescue PluginLoaderError => e
        Dopi.log.error("Step '#{name}': Can't load plugin '#{@step_parser.command.plugin}': #{e.message}")
        false
      end
    end

    def commands
      @commands ||= @nodes.map do |node|
        delete_plugin_defaults
        set_plugin_defaults
        Dopi::Command.create_plugin_instance(@step_parser.command, self, node)
      end
    end

  end
end
