module Dopi
  module Cli

    def self.command_add(base)
      base.class_eval do

        desc 'Add a new plan file to the plan cache'
        arg_name 'plan_file'
        command :add do |c|
          c.action do |global_options,options,args|
            help_now!('Specify a plan file to add') if args.empty?
            help_now!('You can only add one plan') if args.length > 1
            plan = Dopi.add_plan(args[0])
            puts plan.name
          end
        end

      end
    end

  end
end

