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

    def self.create_plan_from_yaml(plan_yaml)
      Dopi::Plan.create_plan_from_hash(YAML.load(plan_yaml))
    end

    def self.create_plan_from_hash(plan_hash)
      plan_parser = DopCommon::Plan.new(plan_hash)
      Dopi::Plan.new(plan_parser)
    end

    def initialize(plan_parser)
      @mutex = Mutex.new
      @plan_parser = plan_parser

      steps.each{|step| state_add_child(step)}
    end

    def run
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

    def nodes
      @nodes ||= parsed_nodes.map do |parsed_node|
        ::Dopi::Node.new(parsed_node)
      end
    end

    def steps
      @steps ||= parsed_steps.map do |parsed_step|
        nodes = (nodes_by_names(parsed_step.nodes) + nodes_by_roles(parsed_step.roles)).uniq
        ::Dopi::Step.new(parsed_step, nodes)
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
