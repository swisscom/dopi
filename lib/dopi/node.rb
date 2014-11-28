#
# This class loades a deployment plan
#
require 'hiera'

module Dopi

  class Node
    attr_reader :fqdn, :role

    def initialize(fqdn, node_config_hash)
      @fqdn = fqdn
      @role = Dopi.configuration.role_default

      # set some basic scope variables if they are
      # not already set
      hostname, domain = fqdn.split('.', 2)
      scope = { 'hostname' => hostname, 'domain' => domain }

      if node_config_hash
        Dopi.log.debug("Merging nodes config into scope")
        Dopi.log.debug(node_config_hash.inspect)
        scope.merge(node_config_hash)

        overwrite_role_from_hash(node_config_hash)
      end

      if Dopi.configuration.use_hiera
        overwrite_role_from_hiera(fqdn, scope)
      end

      raise "No role found for node #{fqdn}" if role.nil?
    end


    def overwrite_role_from_hash(node_config_hash)
      role_variable = Dopi.configuration.role_variable
      if node_config_hash[role_variable]
        @role = node_config_hash[role_variable]
        Dopi.log.debug("found role #{role} for node #{fqdn} in plan yaml")
      else
        Dopi.log.debug("No #{role_varibale} found for node #{fqdn} in plan yaml")
      end
    end


    def overwrite_role_from_hiera(fqdn, scope)
      @@hiera ||= Hiera.new(:config => Dopi.configuration.hiera_yaml)

      # Load the scope from facts if the 
      # directory is configured
      if Dopi.configuration.facts_dir
        facts_yaml = File.join(Dopi.configuration.facts_dir, fqdn + '.yaml')
        facts_scope = {}
        if File.exists?
          facts_scope = YAML.load_file(facts_yaml).values
        else
          Dopi.log.warn("Warning: No fact yaml found for #{fqdn} at #{facts_yaml}")
        end
        merged_scope = facts_scope.merge(scope)
        scope = merged_scope
      end

      @role = Hiera.lookup(Dopi.configuration.role_variable, @role, scope)
    end

  end
end
