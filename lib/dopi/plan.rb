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

      @plan['nodes'].each_key do |fqdn|
        node_config = {}
        ## TODO: I am sure there is a better way to do this
        if @plan['configuration'] === Hash
          if @plan['configuration']['nodes'] === Hash
            if @plan['configuration']['nodes'][fqdn] === Hash
              node_config = @plan['configuration']['nodes'][fqdn]
            end
          end
        end
        role = node_config[Dopi.configuration.role_variable]

        # set some basic scope variables if they are
        # not already set
        hostname, domain = fqdn.split( '.', 2 )
        scope = { 'hostname' => hostname, 'domain' => domain }
        scope.merge( node_config )

        @nodes << Node.new( fqdn, role, scope )
      end
    end

  end

end
