#
# This class loads a deployment plan
#
require 'yaml'

module Dopi
  class Plan
    include Dopi::State

    attr_reader :steps

    def initialize( plan_yaml )
      @mutex = Mutex.new
      @plan_hash  = YAML.load( plan_yaml )

      @steps = build_steps
      #state_add_children(steps)
      steps.each{|step| state_add_child(step)}
    end

    def abort!
      @mutex.synchronize {  @abort = true }
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

    def configuration_hash
      @configuration_hash ||= @plan_hash['configuration'] || {}
    end


    def nodes_configuration_hash
       @nodes_configuration_hash ||= configuration_hash['nodes'] || {}
    end


    def steps_array
      @steps_array ||= @plan_hash['steps'] || []
    end


    def nodes
      @nodes ||= nodes_configuration_hash.map do |fqdn, node_config|
        ::Dopi::Node.new(fqdn, node_config)
      end
    end


    def nodes_by_fqdns(fqdns)
      case fqdns
        when 'all' then nodes
        when Array then nodes.select {|node| fqdns.include? node.fqdn}
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


    def build_steps
      steps_array.map do |step_hash|
        raise "No name specified for step", step_hash unless step_hash['name'].class == String
        nodes = (nodes_by_fqdns(step_hash['nodes']) + nodes_by_roles(step_hash['roles'])).uniq
        ::Dopi::Step.new(step_hash['name'], step_hash['command'], nodes)
      end
    end


    def max_in_flight
      @plan_hash['plan'] && @plan_hash['plan']['max_in_flight'] || nodes.length
    end

  end
end
