#
# This class loades a deployment plan
#
require 'hiera'

module Dopi

  class Node
    attr_reader :fqdn, :role

    def initialize( fqdn, role = Dopi.configuration.role_default, scope = {} )
      @fqdn = fqdn
      @role = role

      # if we use hiera we try to retrieve the role
      # from the data hierarchy instead
      if Dopi.configuration.use_hiera
        @@hiera ||= Hiera.new( :config => Dopi.configuration.hiera_yaml )

        # Load the scope from facts if the 
        # directory is configured
        if Dopi.configuration.facts_dir
          facts_yaml = File.join( Dopi.configuration.facts_dir, fqdn + '.yaml' )
          facts_scope = {}
          if File.exists?
            facts_scope = YAML.load_file( facts_yaml ).values
          else
            ## TODO: use proper loging tool
            puts "Warning: No fact yaml found for #{fqdn} at #{facts_yaml}"
          end
          merged_scope = facts_scope.merge( scope )
          scope = merged_scope
        end

        role = Hiera.lookup( Dopi.configuration.role_variable, role, scope )
      end

      ## TODO: Throw proper exception class
      raise "No role found for node #{fqdn}" if role.nil?
    end

  end

end
