#
# This is a simple hierarchical state tracker which chan keep
# track of it's state based on it's children
#
module Dopi
  class StateTransitionError < StandardError
  end

  module State

    def state
      @state ||= :ready
    end

    def state_auto_evaluate_children
      @auto_evaluate_children ||= true
    end

    def state_auto_evaluate_children=(value)
      @auto_evaluate_children = value
    end

    def state_children
      @state_children ||= []
    end

    def state_add_child(child)
      state_children << child
    end

    def state_children_failed?
      state_children.any? {|child| child.state_failed?}
    end

    def state_children_done?
      state_children.all? {|child| child.state_done?}
    end

    def state_children_ready?
      state_children.all? {|child| child.state_done? || child.state_ready?}
    end

    def state_evaluate_children
      unless state_children.empty? || !state_auto_evaluate_children
        state_finish if state_children_done?
        state_fail   if state_children_failed?
      end
    end

    def state_reset_with_children
      state_reset if state_failed?
      if state_children_failed?
        state_children.each {|child| child.state_reset_with_children }
      end
    end

    def state_ready?
      state_evaluate_children
      state == :ready
    end

    def state_running?
      state_evaluate_children
      state == :running
    end

    def state_done?
      state_evaluate_children
      state == :done
    end

    def state_failed?
      state_evaluate_children
      state == :failed
    end

    def state_run
      raise Dopi::StateTransitionError, "Can't switch to running from #{state.to_s}" unless state == :ready || state == :running
      @state = :running
      state_changed
    end

    def state_finish
      raise Dopi::StateTransitionError, "Can't switch to done from #{state.to_s}" unless state == :running || state == :done
      @state = :done
      state_changed
    end

    def state_fail
      raise Dopi::StateTransitionError, "Can't switch to done from #{state.to_s}" unless state == :running || state == :failed
      @state = :failed
      state_changed
    end

    def state_reset
      raise Dopi::StateTransitionError, "Can't switch to ready from #{state.to_s}" unless state == :failed || state == :ready
      state_children.each {|child| child.state_reset unless child.state_done?}
      @state = :ready
      state_changed
    end

    # returns if the state was changed since the last call of this function
    def state_changed?
      if state_children.empty?
        !(@changed ? @changed = false : true)
      else
        (state_children.count{|child| child.state_changed?} > 0)
      end
    end

    def state_changed
      @changed = true
    end

  end
end
