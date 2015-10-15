# Change Log
All notable changes to DOPi will be documented in this file.

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
