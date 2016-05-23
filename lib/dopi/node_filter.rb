#
# This module provides a method to filter list of nodes.
#
module Dopi
  module NodeFilter

    # filter a list of nodes
    def filter_nodes(nodes, filters)
      return nodes if filters == :all
      include_list = []
      exclude_list = []

      [:nodes, :roles, :nodes_by_config].each do |filter_type|
        pattern_variable_pairs(filters, filter_type) do |pattern, variable|
          include_list += create_node_list(nodes, filter_type, pattern, variable)
        end
      end

      [:exclude_nodes, :exclude_roles, :exclude_nodes_by_config].each do |filter_type|
        pattern_variable_pairs(filters, filter_type) do |pattern, variable|
          exclude_list += create_node_list(nodes, filter_type, pattern, variable)
        end
      end

      (include_list - exclude_list).uniq
    end

    private

    def pattern_variable_pairs(filters, filter_type)
      if filters.respond_to?(filter_type)
        filter = filters.send(filter_type)
        normalize_patterns(filter).each do |variable, patterns|
          [patterns].flatten.collect do |pattern|
            yield(pattern, variable)
          end
        end
      end
    end

    # returns a variable and patterns Array for a filter
    def normalize_patterns(filter)
      case filter
      when String, Symbol, Array then [[nil, filter]]
      when Hash                  then filter.to_a
      else []
      end
    end

    def create_node_list(nodes, filter_type, pattern, variable = nil)
      case pattern
      when :all then nodes
      else
        nodes_list = nodes.select do |node|
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
