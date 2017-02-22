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

    attr_accessor :node_info

    def initialize(node_parser, plan)
      @node_parser = node_parser
      @plan = plan
      @addresses = {}
      @node_info = {}
    end

    def_delegators :@node_parser,
      :name,
      :fqdn,
      :has_name?,
      :config,
      :has_config?,
      :config_includes?,
      :fact,
      :has_fact?,
      :role,
      :has_role?

    def addresses
      [ fqdn, plan_ip_addresses, node_info_ip_addresses ].flatten.uniq
    end

    def address(port)
      @addresses[port] ||= addresses.find {|addr| connection_possible?(addr,port)} or
        raise NodeConnectionError, "Unable to establish a connection for node #{name} on port #{port} over #{addresses.join(', ')}"
    end

    def reset_address(port = nil)
      port.nil? ? @addresses = {} : @addresses.delete(port)
    end

  private

    def plan_ip_addresses
      @node_parser.interfaces.map{|i| [:dhcp, :none].include?(i.ip) ? nil : i.ip}.compact
    end

    def node_info_ip_addresses
      node_info[:ip_addresses] || []
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

  end
end
