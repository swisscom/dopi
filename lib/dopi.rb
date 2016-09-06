require "dopi/error"
require "dopi/signal_handler"
require "dopi/configure"
require "dopi/log"
require "dopi/pluginmanager"
require "dopi/state"
require "dopi/state_store"
require "dopi/command_parser/exec"
require "dopi/command_parser/env"
require "dopi/command_parser/arguments"
require "dopi/command_parser/credentials"
require "dopi/command_parser/exit_code"
require "dopi/command_parser/output"
require "dopi/connector/local"
require "dopi/connector/ssh"
require "dopi/connector/winrm"
require "dopi/command"
require "dopi/command_set"
require "dopi/node"
require "dopi/node_filter"
require "dopi/plan"
require "dopi/step"
require "dopi/step_set"
require "dopi/version"

module Dopi

  def self.valid?(plan_file)
    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    plan = Dopi::Plan.new(plan_parser)
    plan.valid?
  end

  def self.add(plan_file)
    raise StandardError, 'Plan not valid; did not add' unless valid?(plan_file)
    plan_cache.add(plan_file)
  end

  def self.update_plan(plan_file, options = {})
    raise StandardError, 'Plan not valid; did not add' unless valid?(plan_file)
    plan_name = plan_cache.update(plan_file)
    update_state(plan_name, options)
  end

  def self.update_state(plan_name, options = {})
    plan_cache.run_lock(plan_name) do
      state_store = Dopi::StateStore.new(plan_name, plan_cache)
      state_store.update(options)
    end
  end

  def self.remove(plan_name)
    plan_cache.remove(plan_name)
  end

  def self.list
    plan_cache.list
  end

  # TODO: this returns a plan with loaded state at the moment.
  # THIS MAY BE CHANGED IN THE FUTURE!!
  def self.show(plan_name)
    state_store = Dopi::StateStore.new(plan_name, plan_cache)
    plan = get_plan(plan_name)
    plan.load_state(state_store.state_hash)
    plan
  end

  def self.run(plan_name, signal_handling = false, options = {})
    plan_cache.run_lock(plan_name) do
      state_store = Dopi::StateStore.new(plan_name, plan_cache)
      plan = get_plan(plan_name)
      plan.load_state(state_store.state_hash)
      run_signal_handler(plan) if signal_handling
      begin
        state_store_observer = Dopi::StateStoreObserver.new(plan, state_store)
        plan.add_observer(state_store_observer)
        plan.run(options)
      ensure
        state_store_observer.update
      end
    end
  end

  def self.reset(plan_name, force = false)
    plan_cache.run_lock(plan_name) do
      state_store = Dopi::StateStore.new(plan_name, plan_cache)
      plan = get_plan(plan_name)
      plan.load_state(state_store.state_hash)
      plan.state_reset_with_children(force)
      state_store.persist_state(plan)
    end
  end

private

  def self.plan_cache
    @plan_cache ||= DopCommon::PlanCache.new(Dopi.configuration.plan_cache_dir)
  end

  def self.get_plan(plan_name)
    raise StandardError, 'Please update the plan state, there are pending updates' if pending_updates?(plan_name)
    plan_parser = plan_cache.get_plan(plan_name)
    Dopi::Plan.new(plan_parser)
  end

  def self.pending_updates?(plan_name)
    state_store = Dopi::StateStore.new(plan_name, plan_cache)
    state_store.pending_updates?
  end

  def self.run_signal_handler(plan)
    plan.reset_signals
    signal_handler_thread = Thread.new do
      Dopi.log.info("Starting signal handling")
      signal_counter = 0
      Dopi::SignalHandler.new.handle_signals(:INT, :TERM) do
        signal_counter += 1
        case signal_counter
        when 1
          Dopi.log.warn("Signal received! The run will halt after all currently running commands are finished")
          plan.send_signal(:stop)
        when 2
          Dopi.log.error("Signal received! Sending termination signal to all the processes!")
          plan.send_signal(:abort)
        when 3
          Dopi.log.error("Signal received! Sending KILL signal to all the processes!")
          plan.send_signal(:kill)
        end
      end
    end
    signal_handler_thread.abort_on_exception = true
  end

end
