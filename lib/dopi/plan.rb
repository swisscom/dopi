#
# This class loads a deployment plan
#
require 'yaml'

module Dopi
  class Plan
    
    attr_reader :nodes, :steps, :state


    def initialize( plan_yaml )
      @plan_hash  = YAML.load( plan_yaml )

      # Create all the nodes from the plan hash
      @nodes = []
      nodes_config_hash = @plan_hash['configuration']['nodes']
      Dopi.log.debug("Digesting the nodes configuration")
      Dopi.log.debug(nodes_config_hash.inspect)
      @plan_hash['nodes'].each_key do |fqdn|
        @nodes << ::Dopi::Node.new(fqdn, nodes_config_hash[fqdn])
      end

      # Create all the steps from the plan hash
      @steps = []
      @plan_hash['steps'].each do |step_config_hash|
        @steps << ::Dopi::Step.new(step_config_hash, @nodes)
      end
      @step = :ready
    end


    def run
      @state = :running
      # TODO: implement max_in_flight
      max_in_flight = 0
      @steps.each do |step|
        step.run(max_in_flight)
        unless step.state == :done
          @state = :failed
          break
        end
      end
      @state = :done unless @state == :failed
    end

  end
end
