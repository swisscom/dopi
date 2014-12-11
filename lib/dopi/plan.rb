#
# This class loads a deployment plan
#
require 'yaml'

module Dopi
  class Plan
    
    attr_reader :nodes, :steps, :state


    def initialize( plan_yaml )
      @plan_hash  = YAML.load( plan_yaml )
      @state = :ready
    end


    def configuration_hash
      @configuration_hash ||= if @plan_hash['configuration']
        @plan_hash['configuration']
      else
        Dopi.log.warn("No configuration section found in plan file")
        {}
      end
    end


    def nodes_configuration_hash
       @nodes_configuration_hash ||= configuration_hash['nodes'] ? configuration_hash['nodes'] : {}
    end


    def steps_array
      @steps_array ||= @plan_hash['steps'] ? @plan_hash['steps'] : []
    end


    def nodes
      @nodes ||= nodes_configuration_hash.map do |fqdn, node_config|
        ::Dopi::Node.new(fqdn, node_config)
      end
    end


    def steps
      @steps ||= steps_array.map do |step_hash|
        ::Dopi::Step.new(step_hash, nodes)
      end
    end


    def run
      @state = :running
      max_in_flight = 1
      if @plan_hash['plan']
        if @plan_hash['plan']['max_in_flight'].class == Fixnum
          max_in_flight = @plan_hash['plan']['max_in_flight']
        end
      end
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
