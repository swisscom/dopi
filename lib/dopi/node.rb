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

    def initialize(node_parser, configuration)
      @node_parser = node_parser
      @configuration = configuration
    end

    def_delegators :@node_parser, :name

    def role
      @role ||= role_from_hiera || role_from_config || role_default
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

    # This should also resolve over hiera and there should be no need to resolve
    # it internaly. There is currently a problem with the Plan cache which parses
    # the plan and needs to resolve the role before Hiera can access the plan
    def role_from_config
      begin
        @configuration.lookup("hosts/#{name}", Dopi.configuration.role_variable, scope)
      rescue DopCommon::ConfigurationValueNotFound
        nil
      end
    end

    def role_from_hiera
      @@hiera ||= Hiera.new(:config => Dopi.configuration.hiera_yaml)
      @@hiera.lookup(Dopi.configuration.role_variable, nil, scope)
    end

  end
end
