#
# This class loades a deployment plan
#
require 'forwardable'
require 'puppet'
require 'hiera'

module Dopi
  class NoRoleFoundError < StandardError
  end

  class Node
    extend Forwardable

    def initialize(node_parser)
      @node_parser = node_parser
    end

    def_delegators :@node_parser, :name

    def role
      @role ||= Dopi.configuration.use_hiera ? role_from_hiera : role_from_config
    end

  private

    def hostname
      @hostname ||= name.split('.', 2)[0]
    end

    def domain
      @domain ||= name.split('.', 2)[1]
    end 

    def basic_scope
      @basic_scope ||= {
        '::fqdn' => name,
        '::clientcert' => name,
        '::hostname' => hostname,
        '::domain' => domain
      }
    end

    def facts
      facts_yaml = File.join(Dopi.configuration.facts_dir, name + '.yaml')
      if File.exists? facts_yaml
        YAML.load_file(facts_yaml).values
      else
        Dopi.log.warn("No facts found for node #{name} at #{facts_yaml}")
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
        Dopi.log.warn("No role found for #{name} and no default role defined.")
        '-'
      end
    end

    # TODO: replace this with a proper lookup method if
    # the configuration parsing is implemented in dop_common
    def role_from_config
      role_default
    end

    def role_from_hiera
      @@hiera ||= Hiera.new(:config => Dopi.configuration.hiera_yaml)
      @@hiera.lookup(Dopi.configuration.role_variable, role_from_config, scope)
    end

  end
end
