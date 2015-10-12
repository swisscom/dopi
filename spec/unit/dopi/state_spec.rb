require 'spec_helper'

class StateTestKlass
  include Dopi::State
  def name; "dummy"; end
end

describe Dopi::State do

  before :each do
    @child_state1 = StateTestKlass.new
    @child_state2 = StateTestKlass.new
    @state = StateTestKlass.new
    @state.state_add_child(@child_state1)
    @state.state_add_child(@child_state2)
  end

  describe '#new' do
    it 'creates a new state in condition ready' do
      expect(@state.state_ready?).to eq true
    end
  end

  describe 'valid_state_changes' do

    it 'can run and finish a task' do
      @state.state_auto_evaluate_children = false

      # First state transition to running
      expect{@state.state_fail}.to      raise_error Dopi::StateTransitionError
      expect{@state.state_finish}.to    raise_error Dopi::StateTransitionError
      expect{@state.state_reset}.to_not raise_error
      expect{@state.state_run}.to_not   raise_error
      expect(@state.state_running?).to eq true

      # First state transition to done
      expect{@state.state_reset}.to      raise_error Dopi::StateTransitionError
      expect{@state.state_run}.to_not    raise_error
      expect{@state.state_finish}.to_not raise_error
      expect(@state.state_done?).to eq true

      # No more state transitions possible (except finish)
      expect{@state.state_fail}.to       raise_error Dopi::StateTransitionError
      expect{@state.state_reset}.to      raise_error Dopi::StateTransitionError
      expect{@state.state_run}.to        raise_error Dopi::StateTransitionError
      expect{@state.state_finish}.to_not raise_error
    end

    it 'can run, fail a task and reset it again' do
      @state.state_auto_evaluate_children = false

      # First state transition to running
      expect{@state.state_fail}.to      raise_error Dopi::StateTransitionError
      expect{@state.state_finish}.to    raise_error Dopi::StateTransitionError
      expect{@state.state_reset}.to_not raise_error
      expect{@state.state_run}.to_not   raise_error
      expect(@state.state_running?).to eq true

      # First state transition to failed
      expect{@state.state_reset}.to    raise_error Dopi::StateTransitionError
      expect{@state.state_run}.to_not  raise_error
      expect{@state.state_fail}.to_not raise_error
      expect(@state.state_failed?).to eq true

      # Reset the state to ready
      expect{@state.state_finish}.to    raise_error Dopi::StateTransitionError
      expect{@state.state_run}.to       raise_error Dopi::StateTransitionError
      expect{@state.state_fail}.to_not  raise_error
      expect{@state.state_reset}.to_not raise_error
      expect(@state.state_ready?).to eq true
    end

    it 'can run a task in noop and go back to ready again' do
      @state.state_auto_evaluate_children = false

      # First state transition to running
      expect{@state.state_fail}.to      raise_error Dopi::StateTransitionError
      expect{@state.state_finish}.to    raise_error Dopi::StateTransitionError
      expect{@state.state_run_noop}.to_not raise_error
      expect(@state.state_running_noop?).to eq true
      expect{@state.state_fail}.to      raise_error Dopi::StateTransitionError
      expect{@state.state_finish}.to    raise_error Dopi::StateTransitionError
      expect{@state.state_ready}.to_not raise_error
      expect(@state.state_ready?).to eq true
    end

  end

  describe "state changes evaluated from children" do

    it "will fail if one of the children is failed" do
      @state.state_run
      @child_state1.state_run
      @child_state1.state_fail
      expect(@state.state_failed?).to eq true
    end

    it "will be done if all of the children are done" do
      @state.state_run
      @child_state1.state_run
      @child_state1.state_finish
      @child_state2.state_run
      @child_state2.state_finish
      expect(@state.state_done?).to eq true
    end

  end

end

