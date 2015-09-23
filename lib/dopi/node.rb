#
# This class loades a deployment plan
#
require 'forwardable'
require 'puppet'
require 'hiera'
require 'yaml'
require 'socket'
require 'timeout'

module Dopi
  class Node
    extend Forwardable

    @@mutex = Mutex.new
    @@hiera = nil
    @@hiera_config = nil
    
    def initialize(node_parser, plan)
      @node_parser = node_parser
      @plan = plan
      @addresses = {}
    end

    def_delegators :@node_parser, :name

    def config(variable)
      resolve_external(variable) || resolve_internal(variable)
    end

    def role
      @role ||= config(Dopi.configuration.role_variable) || role_default
    end

    def ssh_root_pass
      @sshpass ||= ssh_root_pass_from_hiera || @plan.ssh_root_pass
    end

    def addresses
      [ name, ip_addresses ].flatten
    end

    def address(port)
      @addresses[port] ||= addresses.find {|addr| connection_possible?(addr,port)} or
        raise NodeConnectionError, "Unable to establish a connection for node #{name} on port #{port} over #{addresses.join(', ')}"
    end

  private

    def ip_addresses
      @node_parser.interfaces.map{|i| [:dhcp, :none].include?(i.ip) ? nil : i.ip}.compact
    end

    def connection_possible?(address, port)
      Timeout::timeout(Dopi.configuration.connection_check_timeout.to_i) do
        TCPSocket.new(address, port).close
      end
      Dopi.log.debug("Connection test with #{address}:#{port} for node #{name} ok")
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error, SocketError
      Dopi.log.debug("Connection test with #{address}:#{port} for node #{name} failed")
      false
    end

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
      return {} unless Dopi.configuration.load_facts
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

    def hiera
      @@mutex.synchronize do
        # Create a new Hiera object if the config has changed
        unless Dopi.configuration.hiera_yaml == @@hiera_config
          Dopi.log.debug("Hiera config location changed from #{@@hiera_config.to_s} to #{Dopi.configuration.hiera_yaml.to_s}")
          @@hiera_config = Dopi.configuration.hiera_yaml
          config = YAML.load_file(@@hiera_config)
          config[:logger] = 'dopi'
          @@hiera = Hiera.new(:config => config)
        end
      end
      @@hiera
    end

    def role_default
      if Dopi.configuration.role_default
        Dopi.configuration.role_default
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

    # this will try to resolve the variable over hiera directly
    def resolve_external(variable)
      return nil unless Dopi.configuration.use_hiera
      begin hiera.lookup(variable, nil, scope)
      rescue Psych::SyntaxError => e
        Dopi.log.error("YAML parsing error in hiera data. Make sure you hiera yaml files are valid")
        nil
      end
    end

    def ssh_root_pass_from_hiera
      resolve_external('ssh_root_pass')
    end

  end
end
