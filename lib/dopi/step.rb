#
# Step
#
require 'parallel'

module Dopi
  class Step
    include Dopi::State

    DEFAULT_MAX_IN_FLIGHT = 3

    attr_accessor :plan

    def initialize(step_parser, plan)
      @step_parser = step_parser
      @plan        = plan
      @nodes       = create_node_list(step_parser)

      commands.each{|command| state_add_child(command)}
    end

    def name
      @step_parser.name
    end

    def run(run_options)
      if state_done?
        Dopi.log.info("Step '#{name}' is in state 'done'. Skipping")
        return
      end
      Dopi.log.info("Starting to run step '#{name}'")
      run_for_nodes = case run_options[:run_for_nodes]
                      when :all then @nodes
                      else create_node_list(run_options[:run_for_nodes])
                      end
      run_commands(run_for_nodes, run_options[:noop])
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

  private

    def create_node_list(node_filters)
      include_list = []
      exclude_list = []
      filter_types = [
        :nodes,
        :roles,
        :nodes_by_config
      ]

      filter_types.each do |filter_type|
        filter = node_filters.send(filter_type)
        include_list += create_list_from_filter(filter_type, filter)

        exclude_filter_type = "exclude_#{filter_type}".to_sym
        exclude_filter = node_filters.send(exclude_filter_type)
        exclude_list += create_list_from_filter(exclude_filter_type, exclude_filter)
      end
      (include_list - exclude_list).uniq
    end

     def create_list_from_filter(filter_type, filter)
      decompose_filter(filter).collect do |variable, patterns|
        [patterns].flatten.collect do |pattern|
          filter_nodes(filter_type, pattern, variable)
        end.flatten
      end.flatten
    end

    # returns a variable and patterns Array for a filter
    def decompose_filter(filter)
      case filter
      when String, Symbol, Array then [[nil, filter]]
      when Hash                  then filter.to_a
      else []
      end
    end

    def filter_nodes(filter_type, pattern, variable = nil)
      case pattern
      when :all then @plan.nodes
      else
        nodes_list = @plan.nodes.select do |node|
          case filter_type
          when :nodes, :exclude_nodes                     then node.has_name?(pattern)
          when :roles, :exclude_roles                     then node.has_role?(pattern)
          when :nodes_by_config, :exclude_nodes_by_config then node.config_includes?(variable, pattern)
          when :nodes_by_fact, :exclude_nodes_by_fact     then node.has_fact?(variable, pattern)
          end
        end
        unused_pattern_warning(filter_type, pattern, variable) if nodes_list.empty?
        nodes_list
      end
    end

    def unused_pattern_warning(filter_type, pattern, variable = nil)
      pattern_s = pattern.kind_of?(Regexp) ? "/#{pattern.source}/" : pattern.to_s
      msg = variable.nil? ? "'#{pattern_s}'" : "{'#{variable.to_s}' => '#{pattern_s}'}"
      Dopi.log.warn("Step '#{name}': #{filter_type.to_s} => #{msg} does not match any node!")
    end

  end
end
