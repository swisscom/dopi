# Change Log
All notable changes to DOPi will be documented in this file.

## [0.16.0] - 2017-02-22

IMPORTANT: the config file which used to be under /etc/dop/dopi.conf is now under /etc/dop/dop.conf
because it will now be used by all dop projects and not just by dopi. Make sure you adjust your
installation when updating to > 0.16.

### Added
- it is now possible to include other files in the plan. by using include: path/to/file.yaml
- Use the node info from Dopv to get floating IPs or dynamic IPs for some providers.

### Changes
- A lot of functionality was moved to dop_common to make use of it in all the dop projects

## [0.15.2] - 2017-01-11
### Fixed
- Fix the slow start when using passwords from external tools

## [0.15.1] - 2016-12-14
### Fixed
- Fix the workflow and automatically update the plan before a run

### Added
- Update flag for the add command to make sure we can always add a plan even if it exists

## [0.15.0] - 2016-12-07
### Fixed
- Dopi will now return the correct exit code again if the run failed 

### Added
- The reboot command of the ssh/reboot plugin can now be adjusted with 'reboot_cmd'

### Changed
- The node filter functionality was moved to dop_common
- The remove command will now keep dopv and remove dopi state per default. There are two new options to change the behaviour

## [0.14.3] - 2016-11-28

### Fixed
- Bump version of dop_common to get fixes for various bugs:
  - Add zero padding to the version string for the plan store
  - Removed a misleading error message when a plan was updated and the state was still new
  - Add lower version boundry for hashdiff to make sure the fixed version is used

## [0.14.2] - 2016-11-23

### Fixed
- Assign a proper pty to stdin of processes to prevent the tcgetattr errors of some platforms

## [0.14.1] - 2016-11-16

### Fixed
- The local command executer now clears the environment before executing a command. The only variables set are HOME and PATH with some sane defaults.
- Fixes to the content loader from an executable from dop_common

## [0.14.0] - 2016-11-09

WARNING: This version introduces a new plan store which is incompatible with the old plan store. If you used the plan store of DOPi you will have to re-add all your plans with the new version. There is no automatic migration.

WARNING: The state update feature is in a very early version and there may be corner cases where it does not work as expected. Please always make sure to check the state after an update to verify if the update did what you expected. If you encounter such a case please file a bug report. A workaround is to update the plan with the "--clear" switch which will reset the state, which resembles the old behavior.

### Changed
- Complete re-implementation of the plan store
- Implementation of a proper plan cache to speed up hiera lookups
- The state of a plan will now be updated if a plan is updated
- Complete re-implementation of the state store, which now has a write lock, transactions and atomic updates.
- The update command has a new syntax and the new options clear and ignore to influence how the state should be updated in the case of an error
- remove will now just remove the plan but the state will be preserved
- The show command will now collapse steps per default and only show partial or running steps as expanded. There is a new switch "detailed" to show the full tree
- The show command has a new curses UI for the follow function which will update automatically with inotify if the state changes
- Complete rewrite of the DOPi library API

## Added
- It is now possible to set a title for a command to get a more meaningful output in the show command

## [0.13.1] - 2016-08-10

### Fixed
- Dopi sometimes still tried to access /var/lib/dop when running as a user
- Dopi failed on ruby 2.2 when running a plan from the plan cache
- Plugin timeout did not terminate the processes correctly

## [0.13.0] - 2016-06-22

### Added
- New operation_timeout setting for the winrm connector for long running commands
- The very essential winrm/reboot plugin
- The winrm/puppet_agent plugin

### Fixed
- A run will now stop in the middle of a command sets if an stop command was sent
- winrm/file_exists and winrm/file_contains should now work with paths with spaces
- stderr was not returned correctly for parsing in the winrm connector

### Changed
- Migration of the winrm plugins to the new modularized format
- Update winrm gem to the newest version

## [0.12.0] - 2016-06-13

This release has some pretty significant changes to the SSH connector. It will now encode
the command into a base64 string which will then be decoded on the server side. This should
prevent a lot of the headache around escaping and allow for multiline scripts.

Stuff like this should now be possible:

    - name: 'Execute muliline script'
      nodes: 'all'
      command:
        plugin: 'ssh/custom'
        exec: |
          export FOO="a multiline script"
          echo "this is ${FOO}"
          echo "we don't care about escaping anymore" > /tmp/sometext
          cat /tmp/sometext

You can still get the old behaviour if you set "base64: false" in an ssh plugins. However I
recommend you migrate your scripts instead, which should also make the script look cleaner.

There are also some other smaller changes to the ssh connector which are listed below.

### Changed
- ssh now uses base64 to enable multiline commands and to fix the issues with escaping
- the ssh_check_host_key cli option has gone away. This is now a plugin setting and can
  now be set with the set_plugin_defaults or per plugin instance, which is much more flexible.

### Added
- ssh/reboot plugin

## [0.11.1] - 2016-06-09
- upgrade of dop_common

## [0.11.0] - 2016-05-25
### Added
- Make it possible to limit the running nodes per role with the max_per_role setting
  This can be set per plan and be overwritten by step

### Removed
- plan subhash for max_in_flight is no longer supported and was removed
- Setting the ssh password via ssh_root_pass is no longer supported and was removed

## [0.10.1] - 2016-04-27
### Fixed
- Workaround which hopefully solves the hiera race condition
- Always display stack trace if a bug was detected

## [0.10.0] - 2016-04-18
### Added
- plugin ssh/file_deploy to deploy files to a node
- it is now possible to specify the port for the ssh plugin
- Make it possible to specify more than one command in a step

### Fixed
- the show command does no longer crash if a plan is running

## [0.9.1] - 2016-02-15
### Fixed
- Private key authentication for ssh should now work again.

## [0.9.0] - 2016-01-27
### Added
- Dopi will now support the loading of secrets like passwords from external sources like files
  and the output of executables. See the dop_common documentation for more information.

### Changed
- Dopi will now detect a lot more typos in the node selection via nodes, roles or config
  in the steps or on the cli when running a plan.
- Dopi will now only print warnings instead of trowing an error if a node or role does not
  exist or a pattern does not match anything in a step or on the cli.
- Dopi will now use different default directories and config locations if run by a user so the
  program can actually write to all the necessary files and directories per default.

### Fixed
- Dopi will no longer crash but print an error if the credentials list of a plugin is empty.
- Dopi will no longer crash but print an error if the hiera.yaml is not present.

## [0.8.2] - 2015-11-07
### Fixed
- Make sure log directory actually exists before creating the log file

## [0.8.1] - 2015-11-23
### Fixed
- Make sure ssh really ignores the hosts keys if specified in the options

## [0.8.0] - 2015-11-17
### Added
- winrm/file_exists verify command plugin
- winrm/file_contains verify command plugin

### Changed
- The puppet_agent_run plugin timeout is now 30min per default
- Some debug message improvements

### Fixed
- return code should not be 0 if a dopi run fails

## [0.7.0] - 2015-11-09
### Added
- Dopi now filters all the secrets from the credentials out of the logs
- Dopi will now log to a file structure (default is /var/log/dop/dopi)
- SIGINT and SIGTERM will now try to shutdown the run gracefully. Only the second signal will send a
  SIGTERM to the running processes. The third signal will send a SIGKILL.

### Fixed
- A bug where the state reset took extremely long

## [0.6.2] - 2015-10-15
### Fixed
- Another bug where DOPi crashed because of a missing puppet gem

## [0.6.1] - 2015-10-14
### Fixed
- A bug where DOPi crashed because of a missing puppet gem

## [0.6.0] - 2015-10-12
### Added
- Add version control to DOPi plan dumps and the possibility to update a plan
- Add the options to include and/or exclude nodes from a run.
- Noop mode when using 'dopi run' or 'dopi oneshot'
- Dopi now supports multiple step sets.

### Fixed
- Display a proper error mesage if 'dopi run' is executed with a wrong plan name
- Improve overall DOPi performance by fixing an issue with threads

## [0.5.0] - 2015-09-16
### Added
- Dopi will now test the connection and if not successful automatically try to connect with the configured IPs of the node
- New winrm/wait_for_login command plugin
- The reset command in the executable now supports the '--force' switch to reset from any state
- Verify commands can now be rerun after the command execution with the 'verify_after_run' flag in a plugin.
- New plugin to execute powershell commands on windows over winrm 'winrm/powershell'.

### Changed
- Plan names can now use dashes
- Verify commands are now always executed, even if they where successful in the past

## [0.4.2] - 2015-09-09
### Fixed
- Prevent the ssh/wait_for_login from crashing

## [0.4.1] - 2015-09-07
### Fixed
- Fixed a bug with the winrm/cmd output stream
- Fixed a bug where dopi crashed because of an uninitialized class variable

## [0.4.0] - 2015-08-31
### Added
- Possibility to set/change/delete/overwrite plugin defaults in steps
- New credentials hash to manage login secrets for the plugins
- Basic WinRM plugin to execute commands

### Changed
- SSH plugin now supports the credentals hash for login
- ssh_root_pass will still work, but will display a deprecation warning

## [0.3.1] - 2015-08-17
### Fixed
- Fixed a bug in the ssh/customs plugin where the environment was not set correctly on the node
- Fixed a bug where parallel execution of commands over ssh caused errors
- Show correct errors if the parsing of a hiera yaml file fails

## [0.3.0] - 2015-07-15
### Added
- It is now possible to specify nodes and roles as Regex pattern instead of just names.
- It is now possible to filter nodes with exclude_nodes and exclude_roles in a step.
- It is now possible to add or exclude nodes based on configuration values (hiera) with nodes_by_config and exclude_nodes_by_config.
- The show command now supports a '--follow' flag which will create a display of the state of the plan which gets refreshed

### Changed
- max_in_flight and ssh_root_pass are now global keys and no longer under 'plan'. The old location will still work, but DOPi will show a deprecation warning.
- max_in_flight now supports the values 0 and -1. More info about this is in the Documentation of the DOP plan format.
- Make it possible to set max_in_flight and canary_host globaly and per step.

### Fixed
- Plan validation will now detect nodes which do not exist in steps and roles without nodes.
- Fixed a bug where the role could not be resolved if the plan is not already in the plan cache.

## [0.2.0] - 2015-07-01
### Added
- It is now possible to specify a name for a plan
- 'dopi show' now shows the correct state of a running plan

### Changed
- Colorized CLI output based on log message severity.
- A lot of CLI output improvements

### Fixed
- A bug where the state was not printed if a command failed on runonce mode

## [0.1.11] - 2015-06-17
### Added
- MCollective RPC command plugin
- File replace command plugin (replace a string in a file)

### Fixed
- Missing plugin documentation added

## [0.1.10] - 2015-06-10
### Added
- The custom plugin now automatically sets the environment variable DOP_NODE_FQDN

### Changed
- The standard log level for the dopi CLI is now INFO rather than WARNING

### Fixed
- Loggers from dop_common and hiera are now integrated into dopi logger and obey the log level
- The custom command plugin no longer adds an additional new line after each output log entry
- A bug where Hiera was not correctly initialized in certain situations was fixed
- The puppet agent plugin should now expect error code 2 (changes) as default
- Trace should now also show a stacktrace for unexpected validation Errors
- The initconfig command will now avoid duplicate entries
- Boolean false values from the config file correctly overwrite the default now
