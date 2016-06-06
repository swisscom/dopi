#
# Simple command parser module for environment variable hashes
#
# To set plugin specific defaults for the environment create
# a 'env_defaults' method which returns a hash with:
# { var => val, var2 => val2, ... }
# This hash will be merged with the user specified hash.
#
module Dopi
  module CommandParser
    module Env

      def validate_env
        log_validation_method(:env_valid?, CommandParsingError)
      end

      def env
        env_valid? ? create_env.merge(hash[:env]) : create_env
      end

    private

      def env_valid?
        return false unless hash.kind_of?(Hash) # plugin may not have parameters
        return false if hash[:env].nil? # env is optional
        hash[:env].kind_of?(Hash) or
          raise CommandParsingError, "The value for 'env' has to be a hash"
      end

      def create_env
        defaults = respond_to?(:env_defaults) ? env_defaults : {}
        { 'DOP_NODE_FQDN' => @node.name }.merge(defaults)
      end

    end
  end
end
