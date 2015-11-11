# DOPi Command Plugin: File Contains WinRM Command

This DOPi Plugin will check if the specified file on the node exists.
This plugin is usually used as a verify command to check if a command
has to be executed on a node.

## Plugin Settings:

The winrm/file_exists command plugin is based on the
[winrm powershell command plugin](doc/plugins/winrm/powershell.md) and the
[winrm cmd plugin](doc/plugins/winrm/cmd.md) and inherits all their
parameters.

It will however overwrite the **exec** parameter, so it is not possible to
set a custom command in this plugin.

### file (required)

The file to check

## Example:

    - name: 'Say hello'
      nodes: all
      command:
        verify_commands:
          - plugin: 'winrm/file_exists'
            file: 'C:\some\file.txt'
        plugin: 'winrm/cmd'
        exec: 'echo'
        arguments: '"Hello"'
