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

    attr_reader :id, :plan_parser
 
    def initialize(plan_parser, plan_id)
      @mutex = Mutex.new
      @id = plan_id
      @plan_parser = plan_parser

      steps.each{|step| state_add_child(step)}
    end

    def_delegators :@plan_parser, :configuration, :ssh_root_pass 

    def run
      if state_done?
        Dopi.log.info("Plan is in state 'done'. Nothing to do")
        return
      end
      state_run
      steps.each do |step|
        step.run(max_in_flight)
        break if abort? || state_failed?
      end
    end

    def abort?
      @mutex.synchronize { @abort }
    end

    def abort!
      @mutex.synchronize { @abort = true }
    end

    def reset
      state_reset_with_children
    end

    # The main validation work is done in the dop_common
    # parser. We just add the command plugin parsers
    def valid?
      validity = @plan_parser.valid?
      begin
        validity = false unless steps.all?{|step| step.command_plugin_valid? }
      rescue Dopi::NoRoleFoundError => e
        Dopi.log.warn(e.message) 
      rescue StandardError => e
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
      @steps ||= parsed_steps.map do |parsed_step|
        nodes = (nodes_by_names(parsed_step.nodes) + nodes_by_roles(parsed_step.roles)).uniq
        ::Dopi::Step.new(parsed_step, self, nodes)
      end
    end

  private

    def_delegator  :@plan_parser, :nodes, :parsed_nodes
    def_delegator  :@plan_parser, :steps, :parsed_steps
    def_delegators :@plan_parser, :max_in_flight

    def nodes_by_names(names)
      case names
        when 'all' then nodes
        when Array then nodes.select {|node| names.include? node.name}
        else []
      end
    end

    def nodes_by_roles(roles)
      case roles
        when 'all' then nodes
        when Array then nodes.select {|node| roles.include? node.role}
        else []
      end
    end

  end
end
