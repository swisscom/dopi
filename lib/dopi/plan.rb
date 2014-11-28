#
# This class loads a deployment plan
#
require 'yaml'

module Dopi

  class Plan
    attr_reader :nodes, :steps

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

      create_steps
    end


    # Create all the steps from the plan hash
    def create_steps
      @steps = []

      @plan_hash['steps'].each do |step|
        
        # assemble a list of the nodes assigned to the step
        nodes = []
        unless step['nodes'].nil?
          if step['nodes'].class == String
            if step['nodes'].casecmp('all') == 0
              Dopi.log.debug("Adding all nodes to the step #{step['name']}")
              nodes = @nodes
            else
              raise "Unknown keyword #{step['nodes']} for nodes field in step #{step['name']}"
            end
          elsif step['nodes'].class == Array
            step['nodes'].each do |node_fqdn|
              selected_nodes = @nodes.select {|n| n.fqdn == node_fqdn}
              raise "node #{node_fqdn} is not defined" if selected_nodes == []
              Dopi.log.debug("Adding node to the step #{step['name']}")
              Dopi.log.debug(selected_nodes.inspect)
              nodes += selected_nodes
            end
          else
            raise "nodes field in step #{step['name']} is not an array or keyword"
          end
          Dopi.log.debug("No nodes Array found for step #{step['name']}")
        end
        unless step['roles'].nil?
          if step['roles'].class == Array
            step['roles'].each do |node_role|
              selected_nodes = @nodes.select {|n| n.role == node_role}
              Dopi.log.debug("Adding nodes with role #{node_role} to the step #{step['name']}")
              Dopi.log.debug(selected_nodes.inspect)
              nodes += selected_nodes
            end
          else
            raise "roles field in step #{step['name']} is not an array"
          end
        else
          Dopi.log.debug("No roles Array found for step #{step['name']}")
        end
        nodes.uniq!

        @steps << ::Dopi::Step.new(step['name'], nodes, nil)
      end      
    end

  end

end
