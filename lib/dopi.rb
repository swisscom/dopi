require 'dop_common'
require "dopi/error"
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
require "dopi/command_parser/puppet_run"
require "dopi/connector/local"
require "dopi/connector/ssh"
require "dopi/connector/winrm"
require "dopi/command"
require "dopi/command_set"
require "dopi/node"
require "dopi/plan"
require "dopi/step"
require "dopi/step_set"
require "dopi/version"

module Dopi

  def self.valid?(raw_plan)
    hash, _ = plan_store.read_plan_file(raw_plan)
    plan_parser = DopCommon::Plan.new(hash)
    plan = Dopi::Plan.new(plan_parser)
    plan.valid?
  end

  def self.add(raw_plan)
    raise StandardError, 'Plan not valid; did not add' unless valid?(raw_plan)
    plan_store.add(raw_plan)
  end

  def self.update_plan(raw_plan, options = {})
    raise StandardError, 'Plan not valid; did not add' unless valid?(raw_plan)
    plan_name = plan_store.update(raw_plan)
    update_state(plan_name, options)
    plan_name
  end

  def self.update_state(plan_name, options = {})
    plan_store.run_lock(plan_name) do
      state_store = Dopi::StateStore.new(plan_name, plan_store)
      state_store.update(options)
    end
  end

  def self.remove(plan_name, remove_dopi_state = true, remove_dopv_state = false)
    plan_store.remove(plan_name, remove_dopi_state, remove_dopv_state)
  end

  def self.list
    plan_store.list
  end

  # TODO: this returns a plan with loaded state at the moment.
  # THIS MAY BE CHANGED IN THE FUTURE!!
  def self.show(plan_name)
    ensure_plan_exists(plan_name)
    state_store = Dopi::StateStore.new(plan_name, plan_store)
    plan = get_plan(plan_name)
    plan.load_state(state_store.state_hash)
    plan
  end

  def self.run(plan_name, options = {})
    ensure_plan_exists(plan_name)
    update_state(plan_name)
    plan_store.run_lock(plan_name) do
      state_store = Dopi::StateStore.new(plan_name, plan_store)
      dopv_state_store = plan_store.state_store(plan_name, 'dopv')
      dopv_state_store.transaction(true) do
        dopv_node_info = dopv_state_store[:nodes] || {}
        api_node_info  = options[:node_info] || {}
        options[:node_info] = dopv_node_info.merge(api_node_info)
      end
      plan = get_plan(plan_name)
      plan.load_state(state_store.state_hash)
      manager = nil
      if block_given?
        manager = Thread.new { yield(plan) }
      else
        run_signal_handler(plan)
      end
      begin
        state_store_observer = Dopi::StateStoreObserver.new(plan, state_store)
        plan.add_observer(state_store_observer)
        plan.run(options)
        manager.join if manager
      ensure
        state_store_observer.update
      end
    end
  end

  def self.reset(plan_name, force = false)
    ensure_plan_exists(plan_name)
    plan_store.run_lock(plan_name) do
      state_store = Dopi::StateStore.new(plan_name, plan_store)
      plan = get_plan(plan_name)
      plan.load_state(state_store.state_hash)
      plan.state_reset_with_children(force)
      state_store.persist_state(plan)
    end
  end

  def self.on_state_change(plan_name)
    ensure_plan_exists(plan_name)
    state_store = Dopi::StateStore.new(plan_name, plan_store)
    state_store.on_change do
      yield
    end
  end

private

  def self.plan_store
    @plan_store ||= DopCommon::PlanStore.new(DopCommon.config.plan_store_dir)
  end

  def self.get_plan(plan_name)
    raise StandardError, 'Please update the plan state, there are pending updates' if pending_updates?(plan_name)
    plan_parser = plan_store.get_plan(plan_name)
    Dopi::Plan.new(plan_parser)
  end

  def self.pending_updates?(plan_name)
    state_store = Dopi::StateStore.new(plan_name, plan_store)
    state_store.pending_updates?
  end

  def self.run_signal_handler(plan)
    plan.reset_signals
    signal_handler_thread = Thread.new do
      Dopi.log.info("Starting signal handling")
      signal_counter = 0
      DopCommon::SignalHandler.new.handle_signals(:INT, :TERM) do
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

  def self.ensure_plan_exists(plan_name)
    unless plan_store.list.include?(plan_name)
      raise StandardError, "The plan #{plan_name} does not exist in the plan store"
    end
  end

end
