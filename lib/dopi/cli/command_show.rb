
module Dopi
  module Cli

    def self.command_show(base)
      base.class_eval do

        desc 'Show plan details and state'
        arg_name 'name'
        command :show do |c|
          c.desc 'Do not exit and continuously update the display'
          c.default_value false
          c.switch [:follow, :f]

          c.desc 'Display all details of the tree'
          c.default_value false
          c.switch [:detailed, :d]

          c.action do |global_options,options,args|
            help_now!('Specify a plan name to show') if args.empty?
            help_now!('You can only show one plan') if args.length > 1
            plan_name = args[0]
            if options[:follow]
              begin
                Curses.noecho
                Curses.curs_set(0)
                Curses.init_screen
                Curses.start_color
                Curses.init_pair(1, Curses::COLOR_BLACK, Curses::COLOR_WHITE)
                Curses.init_pair(2, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
                Curses.init_pair(3, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
                Curses.init_pair(4, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
                Curses.init_pair(5, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
                Curses.init_pair(6, Curses::COLOR_RED, Curses::COLOR_BLACK)
                draw_screen(plan_name, options[:detailed])
                Curses.refresh
                Dopi.on_state_change(plan_name) do
                  Curses.clear
                  draw_screen(plan_name, options[:detailed])
                  Curses.refresh
                end
              ensure
                Curses.close_screen
              end
            else
              print_state(plan_name, options[:detailed])
            end
          end
        end

      end
    end

    def self.str_state_color(state, string)
      attr = case state
      when :ready then Curses.color_pair(3)
      when :done then Curses.color_pair(4)
      when :partial then Curses.color_pair(5)
      when :running, :started then Curses.color_pair(5) | Curses::A_BLINK
      when :failed then Curses.color_pair(6)
      else Curses.color_pair(2)
      end
      Curses.attrset(attr)
      Curses.addstr(string)
      Curses.attrset(Curses.color_pair(2))
    end

    def self.draw_screen(plan_name, detailed)
      plan = Dopi.show(plan_name)
      Curses.setpos(0, 0)
      Curses.attrset(Curses.color_pair(1))
      Curses.addstr("DOPi #{Dopi::VERSION} - #{plan.name} [ #{plan.state.to_s} ]".ljust(Curses.cols))
      Curses.setpos(1, 0)
      Curses.attrset(Curses.color_pair(2))
      plan.step_sets.each do |step_set|
        draw_step_set(step_set, detailed)
      end
    end

    def self.draw_step_set(step_set, detailed)
      str_state_color(step_set.state, ' - [' + step_set.state.to_s + '] ' + step_set.name + "\n")
      if detailed or step_set.state_running? or step_set.state_children_partial?
        step_set.steps.each do |step|
          draw_step(step, detailed)
        end
      end
    end

    def self.draw_step(step, detailed)
      str_state_color(step.state, '   - [' + step.state.to_s + '] ' + step.name + "\n")
      if detailed or step.state_running? or step.state_children_partial?
        step.command_sets.each do |command_set|
          draw_command_set(command_set, detailed)
        end
      end
    end

    def self.draw_command_set(command_set, detailed)
      str_state_color(command_set.state, "     - [ #{command_set.state.to_s} ] #{command_set.node.name}\n")
      if detailed or command_set.state_running? or command_set.state_children_partial?
        command_set.commands.each do |command|
          str_state_color(command.state, "       - [ #{command.state.to_s} ] #{command.title}\n")
        end
      end
    end

  end
end

