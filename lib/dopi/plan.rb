#
# This class loads a deployment plan
#
require 'forwardable'
require 'yaml'
require 'dop_common'

module Dopi
  class Plan
    extend Forwardable
    include Dopi::State

    attr_reader :plan_parser, :version
 
    def initialize(plan_parser)
      @version = Dopi::VERSION
      @mutex = Mutex.new
      @plan_parser = plan_parser

      steps.each{|step| state_add_child(step)}
    end

    def_delegators :@plan_parser,
      :name,
      :configuration,
      :credentials,
      :ssh_root_pass,
      :max_in_flight,
      :canary_host

    def run(node_pattern_list = :all)
      run_for_nodes = if node_pattern_list == :all
        nodes
      else
        create_node_list(node_pattern_list)
      end
      if state_done?
        Dopi.log.info("Plan is in state 'done'. Nothing to do")
        return
      end
      steps.each do |step|
        step.run(run_for_nodes)
        break if abort? || state_failed?
      end
    end

    def abort?
      @mutex.synchronize { @abort }
    end

    def abort!
      @mutex.synchronize { @abort = true }
    end

    # The main validation work is done in the dop_common
    # parser. We just add the command plugin parsers
    def valid?
      validity = @plan_parser.valid?
      begin
        validity = false unless steps.all?{|step| step.valid? }
        validity = false unless nodes_valid?
        validity = false unless roles_valid?
      rescue Dopi::NoRoleFoundError => e
        Dopi.log.warn(e.message) 
      rescue => e
        Dopi.configuration.trace ? Dopi.log.error(e) : Dopi.log.error(e.message)
        Dopi.log.warn("Plan: Can't validate the command plugins because of a previous error")
      end
      validity
    end

    def nodes
      @nodes ||= parsed_nodes.map do |parsed_node|
        ::Dopi::Node.new(parsed_node, self)
      end
    end

    def steps
      # Before all the new commands get parsed we have to make sure we
      # Reset all the plugin defaults
      PluginManager.plugin_klass_list('^dopi/command/').each do |plugin_klass|
        plugin_klass.wipe_plugin_defaults
      end
      @steps ||= parsed_steps.map do |parsed_step|
        ::Dopi::Step.new(parsed_step, self, create_node_list(parsed_step))
      end
    end

  private

    def_delegator  :@plan_parser, :nodes, :parsed_nodes
    def_delegator  :@plan_parser, :steps, :parsed_steps

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
      parsed_steps.each do |step|
        return true if step.nodes == :all
        step.nodes.each do |node|
          next if node.kind_of?(Regexp)
          unless nodes.any?{|real_node| real_node.name == node}
            Dopi.log.error("Node '#{node}' in step '#{step.name}' does not exist")
            valid = false
          end
        end
      end
      valid
    end

    def roles_valid?
      valid = true
      parsed_steps.each do |step|
        return true if step.roles == :all
        step.roles.each do |role|
          next if role.kind_of?(Regexp)
          unless nodes.any?{|real_node| real_node.role == role}
            Dopi.log.error("Role '#{role}' in step '#{step.name}' does not contain any nodes")
            valid = false
          end
        end
      end
      valid
    end

    def nodes_by_names(names)
      case names
        when :all then nodes
        when Array then nodes.select do |node|
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
        when :all then nodes
         when Array then nodes.select do |node|
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
        when Array then nodes.select do |node|
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
