#
# This class loades a deployment plan
#
require 'hiera'
require 'yaml'
require 'socket'
require 'timeout'
require 'forwardable'

module Dopi
  class Node
    extend Forwardable

    @@mutex = Mutex.new
    @@mutex_lookup = Mutex.new
    @@hiera = nil
    @@hiera_config = nil

    def initialize(node_parser, plan)
      @node_parser = node_parser
      @plan = plan
      @addresses = {}
    end

    def_delegators :@node_parser,
      :name,
      :has_name?

    def config(variable)
      resolve_external(variable) || resolve_internal(variable)
    end

    def has_config?(variable, pattern)
      pattern_match?(config(variable), pattern)
    end

    def config_includes?(variable, pattern)
      [config(variable)].flatten.any?{|v| pattern_match?(v, pattern)}
    end

    def fact(variable)
      scope[ensure_global_namespace(variable)]
    end

    def has_fact?(variable, pattern)
      pattern_match?(fact(variable), pattern)
    end

    def role
      config(DopCommon.config.role_variable) || role_default
    end

    def has_role?(pattern)
      pattern_match?(role, pattern)
    end

    def ssh_root_pass
      ssh_root_pass_from_hiera || @plan.ssh_root_pass
    end

    def addresses
      [ @node_parser.fqdn, ip_addresses ].flatten
    end

    def address(port)
      @addresses[port] ||= addresses.find {|addr| connection_possible?(addr,port)} or
        raise NodeConnectionError, "Unable to establish a connection for node #{name} on port #{port} over #{addresses.join(', ')}"
    end

    def reset_address(port = nil)
      port.nil? ? @addresses = {} : @addresses.delete(port)
    end

  private

    def pattern_match?(value, pattern)
      case pattern
      when Regexp then value =~ pattern
      else value == pattern
      end
    end

    def ip_addresses
      @node_parser.interfaces.map{|i| [:dhcp, :none].include?(i.ip) ? nil : i.ip}.compact
    end

    def connection_possible?(address, port)
      Timeout::timeout(DopCommon.config.connection_check_timeout.to_i) do
        TCPSocket.new(address, port).close
      end
      Dopi.log.debug("Connection test with #{address}:#{port} for node #{name} ok")
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error, SocketError
      Dopi.log.debug("Connection test with #{address}:#{port} for node #{name} failed")
      false
    end

    def basic_scope
      @basic_scope ||= {
        '::fqdn' => @node_parser.fqdn,
        '::clientcert' => @node_parser.fqdn,
        '::hostname' => @node_parser.hostname,
        '::domain' => @node_parser.domainname
      }
    end

    def facts
      return {} unless DopCommon.config.load_facts
      facts_yaml = File.join(DopCommon.config.facts_dir, @node_parser.fqdn + '.yaml')
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
      merged_scope = basic_scope.merge(facts)
      Hash[merged_scope.map {|fact,value| [ensure_global_namespace(fact), value ]}]
    end

    def hiera
      @@mutex.synchronize do
        # Create a new Hiera object if the config has changed
        unless DopCommon.config.hiera_yaml == @@hiera_config
          Dopi.log.debug("Hiera config location changed from #{@@hiera_config.to_s} to #{DopCommon.config.hiera_yaml.to_s}")
          @@hiera_config = DopCommon.config.hiera_yaml
          config = {}
          if File.exists?(@@hiera_config)
            config = YAML.load_file(@@hiera_config)
          else
            Dopi.log.error("Hiera config #{@@hiera_config} not found! Using empty config")
          end
          # set the plan_store defaults
          config[:dop] ||= { }
          unless config[:dop].has_key?(:plan_store_dir)
            config[:dop][:plan_store_dir] = DopCommon.config.plan_store_dir
          end
          config[:logger] = 'dopi'
          @@hiera = Hiera.new(:config => config)
        end
      end
      @@hiera
    end

    def role_default
      if DopCommon.config.role_default
        DopCommon.config.role_default
      else
        Dopi.log.warn("No role found for #{name} and no default role defined.")
        '-'
      end
    end

    # This will try to resolve the config variable from the plan configuration hash.
    # This is needed in case the plan is not yet added to the plan cache
    # (in case of validation) and hiera can't resolve it over the plugin,
    # but we still need the information about the node config.
    def resolve_internal(variable)
      return nil unless DopCommon.config.use_hiera
      @@mutex_lookup.synchronize do
        begin
          hiera # make sure hiera is initialized
          answer = nil
          Hiera::Backend.datasources(scope) do |source|
            Dopi.log.debug("Hiera internal: Looking for data source #{source}")
            data = nil
            begin
              data = @plan.configuration.lookup(source, variable, scope)
            rescue DopCommon::ConfigurationValueNotFound
              next
            else
              break if answer = Hiera::Backend.parse_answer(data, scope)
            end
          end
        rescue StandardError => e
          Dopi.log.debug(e.message)
        end
        Dopi.log.debug("Hiera internal: answer for variable #{variable} : #{answer}")
        return answer
      end
    end

    # this will try to resolve the variable over hiera directly
    def resolve_external(variable)
      return nil unless DopCommon.config.use_hiera
      @@mutex_lookup.synchronize do
        begin hiera.lookup(variable, nil, scope)
        rescue Psych::SyntaxError => e
          Dopi.log.error("YAML parsing error in hiera data. Make sure you hiera yaml files are valid")
          nil
        end
      end
    end

    def ssh_root_pass_from_hiera
      resolve_external('ssh_root_pass')
    end

  end
end
