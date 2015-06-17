# DOPi Command Plugin: File Contains SSH Command

This DOPi Plugin will check if the specified file on the node exists.
This plugin is usually used as a verify command to check if a command
has to be executed on a node.

## Plugin Settings:

The ssh/file_exists command plugin is based on the
[ssh custom command plugin](doc/plugins/ssh/custom.md) and the
[custom command plugin](doc/plugins/custom.md) and inherits all their
parameters.

It will however overwrite the **exec** parameter, so it is not possible to
set a custom command in this plugin.

### file (required)

The file to check

## Example:

    - name: 'Install Puppet'
      nodes: all
      command:
        plugin: 'ssh/custom'
        verify_commands:
          - plugin: 'ssh/file_exists'
            file: '/usr/bin/puppet'
      exec: 'yum'
      arguments: 'install -y puppet'
