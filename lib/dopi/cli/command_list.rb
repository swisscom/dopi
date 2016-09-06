module Dopi
  module Cli

    def self.command_list(base)
      base.class_eval do

        desc 'Show the list of plans in the dopi plan cache'
        command :list do |c|
          c.action do |global_options,options,args|
            puts Dopi.list
          end
        end

      end
    end

  end
end

