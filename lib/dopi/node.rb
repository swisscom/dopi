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
      :has_name?,
      :config,
      :has_config?,
      :config_includes?,
      :fact,
      :has_fact?,
      :role,
      :has_role?

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

    def ssh_root_pass_from_hiera
      resolve_external('ssh_root_pass')
    end

  end
end
