module Dopi
  module Cli

    def self.command_remove(base)
      base.class_eval do

        desc 'Remove an existing plan from the plan cache'
        arg_name 'name'
        command :remove do |c|
          c.action do |global_options,options,args|
            help_now!('Specify a plan name to remove') if args.empty?
            help_now!('You can only remove one plan') if args.length > 1
            plan_name = args[0]
            Dopi.remove(plan_name)
          end
        end

      end
    end

  end
end

