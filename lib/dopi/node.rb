#
# This class loades a deployment plan
#
require 'puppet'
require 'hiera'

module Dopi

  class Node
    attr_reader :fqdn

    def initialize(fqdn, node_config)
      @fqdn = fqdn
      @node_config = node_config
    end

    def hostname
      @hostname ||= @fqdn.split('.', 2)[0]
    end

    def domain
      @domain ||= @fqdn.split('.', 2)[1]
    end 

    def basic_scope
      @basic_scope ||= {
        '::fqdn' => @fqdn,
        '::clientcert' => @fqdn,
        '::hostname' => hostname,
        '::domain' => domain
      }
    end

    def facts
      facts_yaml = File.join(Dopi.configuration.facts_dir, @fqdn + '.yaml')
      if File.exists? facts_yaml
        YAML.load_file(facts_yaml).values
      else
        Dopi.log.warning("No facts found for node #{@fqdn} at #{facts_yaml}")
        {}
      end
    end

    def ensure_global_namespace(fact)
      fact =~ /^::/ ? fact : '::' + fact
    end

    def scope
      merged_scope = facts.merge(basic_scope)
      @scope = Hash[merged_scope.map {|fact,value| [ensure_global_namespace(fact), value ]}]
    end

    def role_default
      if Dopi.configuration.role_default
        Dopi.configuration.role_default
      else
        raise "No role found for #{fqdn} and no default role defined"
      end
    end

    def role_from_config
      conf_role = @node_config[Dopi.configuration.role_variable]
      conf_role.nil? ? role_default : conf_role
    end

    def role_from_hiera
      @@hiera ||= Hiera.new(:config => Dopi.configuration.hiera_yaml)
      @@hiera.lookup(Dopi.configuration.role_variable, role_from_config, scope)
    end

    def role
      @role ||= Dopi.configuration.use_hiera ? role_from_hiera : role_from_config
    end

  end
end
