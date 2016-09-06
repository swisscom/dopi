#
# The DOPi CLI main module
#
require 'gli'
require 'dopi'
require 'dopi/cli/log'
require 'dopi/cli/global_options'
require 'dopi/cli/node_selection'
require 'dopi/cli/command_run'
require 'dopi/cli/command_validate'
require 'dopi/cli/command_add'
require 'dopi/cli/command_update'
require 'dopi/cli/command_list'
require 'dopi/cli/command_remove'
require 'dopi/cli/command_show'
require 'dopi/cli/command_reset'
require 'logger/colors'
require 'curses'
require 'yaml'
require 'fileutils'

module Dopi
  module Cli
    include GLI::App
    extend self

    program_desc 'DOPi Command line Client'
    version Dopi::VERSION

    subcommand_option_handling :normal
    arguments :strict

    config_file Dopi.configuration.config_file

    desc 'Verbosity of the command line tool'
    default_value 'INFO'
    arg_name 'Verbosity'
    flag [:verbosity, :v]

    global_options(self)

    pre do |global,command,options,args|
      Dopi.configure = global
      ENV['GLI_DEBUG'] = 'true' if global[:trace] == true
      initialize_logger(global[:log_level], global[:verbosity])
      true
    end

    command_run(self)
    command_validate(self)
    command_add(self)
    command_update(self)
    command_list(self)
    command_remove(self)
    command_show(self)
    command_reset(self)

  end
end
