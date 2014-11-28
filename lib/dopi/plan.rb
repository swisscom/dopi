#
# This class loades a deployment plan
#
require 'yaml'

module Dopi

  class Plan
    attr_reader :nodes

    def initialize( plan_yaml )
      @plan  = YAML.load( plan_yaml )
      @nodes = []

      nodes_config = @plan['configuration']['nodes']
      Dopi.log.debug("Digesting the nodes configuration")
      Dopi.log.debug(nodes_config.inspect)

      @plan['nodes'].each_key do |fqdn|
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

        @nodes << Node.new( fqdn, role, scope )
      end
    end

  end

end
