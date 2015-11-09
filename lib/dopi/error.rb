#
# Various error classes for DOPi
#
# Error hierarchy:
#
#   PluginLoaderError
#   StateTransitionError
#   NoRoleFoundError
#   CommandParsingError
#   CommandExecutionError
#     CommandExecutionError
#       ConnectionError
#         NodeConnectionError
#         CommandConnectionError
#
module Dopi
  class PluginLoaderError < StandardError
  end

  class StateTransitionError < StandardError
  end

  class NoRoleFoundError < StandardError
  end

  class CommandParsingError < StandardError
  end

  class CommandExecutionError < StandardError
  end

  class GracefulExit < StandardError
  end

  class ConnectionError < CommandExecutionError
  end

  class NodeConnectionError < ConnectionError
  end

  class CommandConnectionError < ConnectionError
  end
end
