#
# DOP Plan Hiera Backend
#

class Hiera
  module Backend
    class Dop_backend

      def initialize(cache = nil)
        Hiera.debug('Hiera DOP backend starting')
        begin
          require 'dopi'
        rescue
          require 'rubygems'
          require 'dopi'
        end

        plan_dir = Config[:dop][:plan_dir] || Dop.configuration.plan_dir

        @plan_cache = Dopi::Cache.new(plan_dir)

        Hiera.debug('DOP Plan Cache Loaded')
      end

      def find_plan(node_name)
        begin
          plan_id = @plan_cache.list.find do |id|
            @plan_cache.get(id).find_node(node_name)
          end
          @plan_cache.get(plan_id)
        rescue StandardError => e
          nil
        end
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil
        begin
          Hiera.debug(scope.inspect)
          configuration = find_plan(scope['::clientcert']).configuration
          Backend.datasources(scope, order_override) do |source|
            Hiera.debug("Looking for data source #{source}")
            data = nil
            begin
               data = configuration.lookup(source, key, scope)
            rescue DopCommon::ConfigurationValueNotFound
              next
            else
              break if answer = Backend.parse_answer(data, scope)
            end
          end
        rescue StandardError => e
          Hiera.debug(e.message)
          nil
        end
        return answer
      end

    end
  end
end
