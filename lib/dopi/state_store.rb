#
# This is the DOPi state store which persists the state
# of the steps between and during runs.
#
module Dopi
  class StateStore

    def initialize(plan_name, plan_cache)
      @plan_cache  = plan_cache
      @plan_name   = plan_name
      @state_store = @plan_cache.state_store(plan_name, 'dopi')
    end

    def update(options = {})
      @state_store.update do |plan_diff|
        Dopi.log.info("Updating plan #{@plan_name}. This is the diff:")
        Dopi.log.info(plan_diff.to_s)
      end
    end

    def persist_state(plan)
      @state_store.transaction do
        @state_store[:state] = plan.state_hash
      end
    end

    def state_hash
      @state_store.transaction(true) do
        @state_store[:state] || {}
      end
    end

    def method_missing(m, *args, &block)
      @state_store.send(m, *args, &block)
    end

  end

  class StateStoreObserver

    def initialize(plan, state_store)
      @plan        = plan
      @state_store = state_store
    end

    def update
      @state_store.persist_state(@plan)
    end

  end
end
