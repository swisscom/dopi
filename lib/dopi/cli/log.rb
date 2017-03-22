#
# Initializes the logger for the CLI
#

module Dopi
  module Cli

    def self.state(plan_name, detailed = false)
      plan = Dopi.show(plan_name)
      result = "[#{plan.state.to_s}] #{plan.name}\n"
      plan.step_sets.each do |step_set|
        result << "  [#{step_set.state.to_s}] #{step_set.name}\n"
        step_set.steps.each do |step|
          result << "    [#{step.state.to_s}] #{step.name}\n"
          if detailed or step.state_running? or step.state_children_partial?
            step.command_sets.each do |command_set|
              result << "      [#{command_set.state.to_s}] #{command_set.name}\n"
              command_set.commands.each do |command|
                result << "        [#{command.state.to_s}] #{command.title}\n"
              end
            end
          end
        end
      end
      return result
    end

    def self.print_state(plan_name, detailed = false)
      puts state(plan_name, detailed)
    end

  end
end
