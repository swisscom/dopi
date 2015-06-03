#
# Route Hiera Log entries to DOPi Logger
#
require 'dopi'

class Hiera
  module Dopi_logger
    class << self

      def warn(msg)
        Dopi.log.warn('Hiera: ' +msg)
      end

      def debug(msg)
        Dopi.log.debug('Hiera: ' + msg)
      end

    end
  end
end
