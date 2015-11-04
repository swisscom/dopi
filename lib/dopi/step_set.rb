#
# This class parses loades step sets
#
require 'forwardable'
require 'yaml'
require 'dop_common'

module Dopi
  class StepSet
    extend Forwardable
    include Dopi::State

    def initialize(parsed_step_set, plan)
      @parsed_step_set = parsed_step_set
      @plan = plan
      steps.each{|step| state_add_child(step)}
    end

    def_delegators :@parsed_step_set, :name

    def run(run_options)
      if state_done?
        Dopi.log.info("Step set #{name} is in state 'done'. Nothing to do")
        return
      end
      unless state_ready?
        raise StandardError, "Step set #{name} is not in state 'ready'. Try to reset the plan"
      end
      run_for_nodes = case run_options[:run_for_nodes]
                      when :all then nodes
                      else create_node_list(run_options[:run_for_nodes])
                      end
      steps.each do |step|
        step.run(run_for_nodes, run_options[:noop])
        break if signals[:stop] || state_failed?
      end
    end

    # The main validation work is done in the dop_common
    # parser. We just add the command plugin parsers
    def valid?
      validity = true
      validity = false unless steps.all?{|step| step.valid? }
      validity = false unless nodes_valid?
      validity = false unless roles_valid?
      validity
    rescue Dopi::NoRoleFoundError => e
      Dopi.log.warn(e.message)
    end

    def steps
      # Before all the new commands get parsed we have to make sure we
      # Reset all the plugin defaults
      PluginManager.plugin_klass_list('^dopi/command/').each do |plugin_klass|
        plugin_klass.wipe_plugin_defaults
      end
      @steps ||= @parsed_step_set.steps.map do |parsed_step|
        ::Dopi::Step.new(parsed_step, @plan, create_node_list(parsed_step))
      end
    end

  private

    def create_node_list(parsed_step)
      list = []
      list += nodes_by_names(parsed_step.nodes)
      list += nodes_by_roles(parsed_step.roles)
      parsed_step.nodes_by_config.each do |variable, pattern|
        list += nodes_by_config(variable, pattern)
      end
      list -= nodes_by_names(parsed_step.exclude_nodes)
      list -= nodes_by_roles(parsed_step.exclude_roles)
      parsed_step.exclude_nodes_by_config.each do |variable, pattern|
        list -= nodes_by_config(variable, pattern)
      end
      list.uniq
    end

    def nodes_valid?
      valid = true
      @parsed_step_set.steps.each do |step|
        return true if step.nodes == :all
        step.nodes.each do |node|
          next if node.kind_of?(Regexp)
          unless @plan.nodes.any?{|real_node| real_node.name == node}
            Dopi.log.error("Node '#{node}' in step '#{step.name}' does not exist")
            valid = false
          end
        end
      end
      valid
    end

    def roles_valid?
      valid = true
      @parsed_step_set.steps.each do |step|
        return true if step.roles == :all
        step.roles.each do |role|
          next if role.kind_of?(Regexp)
          unless @plan.nodes.any?{|real_node| real_node.role == role}
            Dopi.log.error("Role '#{role}' in step '#{step.name}' does not contain any nodes")
            valid = false
          end
        end
      end
      valid
    end

    def nodes_by_names(names)
      case names
        when :all then @plan.nodes
        when Array then @plan.nodes.select do |node|
          names.any? do |name|
            case name
            when Regexp then node.name =~ name
            else node.name == name
            end
          end
        end
        else []
      end
    end

    def nodes_by_roles(roles)
      case roles
        when :all then @plan.nodes
         when Array then @plan.nodes.select do |node|
          roles.any? do |role|
            case role
            when Regexp then node.role =~ role
            else node.role == role
            end
           end
         end
        else []
      end
    end

    def nodes_by_config(variable, patterns)
      case patterns
        when Array then @plan.nodes.select do |node|
          [node.config(variable)].flatten.any? do |config_value|
            patterns.any? do |pattern|
              case pattern
              when Regexp then config_value =~ pattern
              else config_value == pattern
              end
            end
          end
        end
        else []
      end
    end

  end
end
