#
# Various error classes for DOPi
#

module Dopi
  class ConnectionError < StandardError
  end

  class PluginLoaderError < StandardError
  end

  class StateTransitionError < StandardError
  end

  class NoRoleFoundError < StandardError
  end

  class NodeConnectionError < ConnectionError
  end

  class CommandParsingError < StandardError
  end

  class CommandExecutionError < StandardError
  end

  class CommandConnectionError < ConnectionError
  end
end
