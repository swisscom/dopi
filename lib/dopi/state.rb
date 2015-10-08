#
# This is a simple hierarchical state tracker which chan keep
# track of it's state based on it's children
#
require 'observer'

module Dopi
  module State
    include Observable

    def state
      @state ||= :ready
    end

    def state_auto_evaluate_children
      @auto_evaluate_children = true if @auto_evaluate_children.nil?
      @auto_evaluate_children
    end

    def state_auto_evaluate_children=(value)
      @auto_evaluate_children = value
    end

    def state_children
      @state_children ||= []
    end

    def state_add_child(child)
      state_children << child
      child.add_observer(self)
    end

    def state_children_ready?
      state_children.any? {|child| child.state_ready?}
    end

    def state_children_running_noop?
      state_children.any? {|child| child.state_running_noop?}
    end

    def state_children_running?
      state_children.any? {|child| child.state_running?}
    end

    def state_children_failed?
      state_children.any? {|child| child.state_failed?}
    end

    def state_children_done?
      state_children.all? {|child| child.state_done?}
    end

    def update
      unless state_children.empty? || !state_auto_evaluate_children
        if    state_children_failed?       then @state = :failed
        elsif state_children_done?         then @state = :done
        elsif state_children_running?      then @state = :running
        elsif state_children_running_noop? then @state = :running_noop
        elsif state_children_ready?        then @state = :ready
        end
        Dopi.log.debug("State of #{name} updated")
        state_changed
      end
    end

    def state_reset_with_children(force = false)
      state_reset(force) if state_failed? or force
      if state_children_failed? or force
        state_children.each {|child| child.state_reset_with_children(force) }
      end
    end

    def state_ready?
      state == :ready
    end

    def state_running?
      state == :running
    end

    def state_running_noop?
      state == :running_noop
    end

    def state_done?
      state == :done
    end

    def state_failed?
      state == :failed
    end

    def state_run
      return if state == :running
      raise Dopi::StateTransitionError, "Can't switch to running from #{state.to_s}" unless state == :ready
      @state = :running
      state_changed
    end

    def state_run_noop
      return if state == :running_noop
      raise Dopi::StateTransitionError, "Can't switch to running_noop from #{state.to_s}" unless state == :ready
      @state = :running_noop
      state_changed
    end

    def state_ready
      return if state == :ready
      raise Dopi::StateTransitionError, "Can't switch to ready from #{state.to_s}" unless state == :running_noop
      @state = :ready
      state_changed
    end

    def state_finish
      return if state == :done
      raise Dopi::StateTransitionError, "Can't switch to done from #{state.to_s}" unless state == :running
      @state = :done
      state_changed
    end

    def state_fail
      return if state == :failed
      raise Dopi::StateTransitionError, "Can't switch to done from #{state.to_s}" unless state == :running
      @state = :failed
      state_changed
    end

    def state_reset(force = false)
      if force
        state_children.each {|child| child.state_reset(force)}
      else
        raise Dopi::StateTransitionError, "Can't switch to ready from #{state.to_s}" unless state == :failed || state == :ready
        state_children.each {|child| child.state_reset unless child.state_done?}
      end
      @state = :ready
      state_changed
    end

    def state_changed
      Dopi.log.debug("State of #{name} changed")
      changed
      notify_observers
    end

  end
end
