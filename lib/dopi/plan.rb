#
# This class loads a deployment plan
#
require 'yaml'

module Dopi

  class Plan
    attr_reader :nodes, :steps

    def initialize( plan_yaml )
      @plan_hash  = YAML.load( plan_yaml )

      create_nodes
      create_steps
    end

    # Create all the nodes from the plan hash
    def create_nodes
      @nodes = []
      nodes_config = @plan_hash['configuration']['nodes']
      Dopi.log.debug("Digesting the nodes configuration")
      Dopi.log.debug(nodes_config.inspect)

      @plan_hash['nodes'].each_key do |fqdn|
        # set some basic scope variables if they are
        # not already set
        hostname, domain = fqdn.split( '.', 2 )
        scope = { 'hostname' => hostname, 'domain' => domain }

        # Merge with nodes config from the plan and indentify
        # the role if it is defined here
        role = nil
        if nodes_config[fqdn]
          Dopi.log.debug("Merging nodes config into scope")
          Dopi.log.debug(nodes_config[fqdn].inspect)
          scope.merge( nodes_config[fqdn] )

          role_variable = Dopi.configuration.role_variable
          if nodes_config[fqdn][role_variable]
            role = nodes_config[fqdn][role_variable]
            Dopi.log.debug("found role #{role} for node #{fqdn}")
          else
            Dopi.log.debug("No #{role_varibale} found for node #{fqdn}")
          end
        end

        @nodes << ::Dopi::Node.new( fqdn, role, scope )
      end
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
