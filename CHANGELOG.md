# Change Log
All notable changes to DOPi will be documented in this file.

## [Unreleased]
### Added
- It is now possible to specify nodes and roles as Regex pattern instead of just names.
- It is now possible to filter nodes with nodes_exclude and roles_exclude in a step.

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