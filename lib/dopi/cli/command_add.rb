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
            plan_file = args[0]
            plan_name = Dopi.add(plan_file)
            puts plan_name
          end
        end

      end
    end

  end
end

