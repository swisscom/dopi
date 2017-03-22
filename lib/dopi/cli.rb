#
# The DOPi CLI main module
#
require 'gli'
require 'dopi'
require 'dop_common/cli/node_selection'
require 'dop_common/cli/log'
require 'dop_common/cli/global_options'
require 'dopi/cli/log'
require 'dopi/cli/global_options'
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

    config_file DopCommon.config.config_file

    DopCommon::Cli.global_options(self)
    global_options(self)

    pre do |global,command,options,args|
      DopCommon.configure = global
      ENV['GLI_DEBUG'] = 'true' if global[:trace] == true
      DopCommon::Cli.initialize_logger('dopi.log', global[:log_level], global[:verbosity], global[:trace])
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
