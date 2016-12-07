module Dopi
  module Cli

    def self.command_remove(base)
      base.class_eval do

        desc 'Remove an existing plan from the plan cache'
        arg_name 'name'
        command :remove do |c|
          c.desc 'Keep the DOPi state file'
          c.default_value false
          c.switch [:keep_dopi_state]

          c.desc 'Remove the DOPv state file (THIS WILL REMOVE THE DISK INFO)'
          c.default_value false
          c.switch [:remove_dopv_state]

          c.action do |global_options,options,args|
            help_now!('Specify a plan name to remove') if args.empty?
            help_now!('You can only remove one plan') if args.length > 1
            plan_name = args[0]
            Dopi.remove(plan_name, !options[:keep_dopi_state], options[:remove_dopv_state])
          end
        end

      end
    end

  end
end

