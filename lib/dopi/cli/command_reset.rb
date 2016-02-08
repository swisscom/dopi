module Dopi
  module Cli

    def self.command_reset(base)
      base.class_eval do

        desc 'Reset a failed plan'
        arg_name 'name'
        command :reset do |c|
          c.desc 'Force reset the states back to ready from every state'
          c.default_value false
          c.switch [:force, :f]

          c.action do |global_options,options,args|
            help_now!('Specify a plan name to run') if args.empty?
            help_now!('You can only run one plan') if args.length > 1
            plan = Dopi.load_plan(args[0])
            plan.state_reset_with_children(options[:force])
            Dopi.save_plan(plan)
            print_state(plan)
          end
        end

      end
    end

  end
end

