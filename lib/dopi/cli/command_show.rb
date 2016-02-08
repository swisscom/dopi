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

          c.action do |global_options,options,args|
            help_now!('Specify a plan name to show') if args.empty?
            help_now!('You can only show one plan') if args.length > 1
            if options[:follow]
              begin
                Curses.noecho
                Curses.curs_set(0)
                Curses.init_screen
                plan = Dopi.load_plan(args[0])
                while true
                  begin
                    reload_plan = Dopi.load_plan(args[0])
                    plan = reload_plan if reload_plan.kind_of?(Dopi::Plan)
                  rescue
                  end
                  Curses.setpos(0, 0)
                  Curses.addstr(state(plan))
                  Curses.refresh
                  sleep(1)
                end
              ensure
                Curses.close_screen
              end
            else
              print_state(Dopi.load_plan(args[0]))
            end
          end
        end

      end
    end

  end
end

