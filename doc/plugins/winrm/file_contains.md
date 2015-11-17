# DOPi Command Plugin: File Contains WinRM Command

This DOPi Plugin will check if the specified file on the node contains a
specific pattern. This plugin is usually used as a verify command to check
if a command has to be executed on a node.

## Plugin Settings:

The winrm/file_contains command plugin is based on the
[winrm powershell command plugin](doc/plugins/winrm/powershell.md) and the
[winrm cmd command plugin](doc/plugins/winrm/cdm.md) and inherits all their
parameters.

It will however overwrite the **exec** parameter, so it is not possible to
set a custom command in this plugin.

### file (required)

The file to check

### pattern (required)

The regular expression to check against

## Example:

    - name "Run puppet on a node"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'winrm/cmd'
        verify_commands:
          - plugin: 'winrm/file_contains'
            file: 'C:\puppet\puppet.conf'
            pattern: 'puppetmaster.example.com'
        exec: 'puppet'
        arguments:
          'agent': '--test'
          '--server': 'puppetmaster.example.com'
