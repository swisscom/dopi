# DOPi Command Plugin: File Replace SSH Command

This DOPi Plugin to replace a search pattern with a replacement string
in a file on a node over ssh. This plugin uses sed to replace the string,
keep that in mind if you define the pattern String.

## Plugin Settings:

The ssh/file_replace command plugin is based on the
[ssh/file_contains](doc/plugins/ssh/file_contains.md),
[ssh custom command plugin](doc/plugins/ssh/custom.md) and the
[custom command plugin](doc/plugins/custom.md) and inherits all their
parameters.

It will however overwrite the **exec** parameter, so it is not possible to
set a custom command in this plugin.

### replacement (required)

This the replacement string the that will be substituted for the found pattern.

### global (optional)

`default: false`

If false it will only replace the first match, if true it will replace them all.

## Example:

    - name "replace the server in the Puppet config"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'ssh/file_replace'
        file: '/etc/puppet/puppet.conf'
        pattern: 'puppet.example.com'
        replacement: 'somethingelse.example.com'
