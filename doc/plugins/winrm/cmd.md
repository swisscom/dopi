# DOPi Command Plugin: WinRM Command executor

This DOPi Plugin will execute a command on Windows with WinRM.

## Plugin Settings:

### credentials (optional)

`default: []`

The winrm plugin and all the plugins that inherit from it can use
credentials from the credentials hash in the plan to login.

    credentials:
      'windows_staging_login':
        type: :username_password
        username: 'administrator'
        password: 'foo'

    steps:
      - name: 'set winrm login credentials'
        command:
          plugin: 'winrm/cmd'
          credentials: 'windows_staging_login'
          exec: 'somecommand'

You can also specify multiple credentials and the winrm plugin will try each one
of them in turn to login to the node.

    credentials:
      'windows_staging_login':
        type: :username_password
        username: 'administrator'
        password: 'foo'
      'windows_prod_login':
        type: :kerberos
        realm: 'FOOO'

    steps:
      - name: 'set winrm login credentials'
        command:
          plugin: 'winrm/cmd'
          credentials:
            - 'windows_staging_login'
            - 'windows_prod_login'
          exec: 'somecommand'

This can be set in each plugin (don't forget the validator plugins) or via
the set_plugin_defaults hash. The plugin defaults will be preserved for
subsequent steps until it is altered or deleted.

    credentials:
      'windows_staging_login':
        type: :username_password
        username: 'administrator'
        password: 'foo'
      'windows_prod_login':
        type: :kerberos
        realm: 'FOOO'

    steps:
      - name: 'set winrm login credentials'
        set_plugin_defaults:
          - plugins: '/^ssh/'
            :credentials:
              - 'windows_staging_login'
              - 'windows_prod_login'
        command:
          plugin: 'winrm/cmd'
          exec: 'somecommand'


(See dop_common plan format for more options)

### exec (required)

The command the plugin should execute for every node.

### arguments (optional)

`default: ""`

The arguments for the command. This can be set by a string as an array or
as a hash. All the elements of the hash and the array will be flattened
and joined with a space.

### port (optional)

`default: 5985`

The port where the service is listening on the remote machines.

### ssl (optional)

`default: true`

Communicate with the node over ssl

### ca_trust_path (optional)

`default: nil`

Point to another CA trust ca trust path

### disable_sspi (optional)

`default: false`

Disable the security support provider interface.

### basic_auth_only (optional)

`default: false`

Use basic auth only

### operation_timeout (optional)

`default: plugin_timeout - 5s`

Timeout for the winrm command to respond. This will default to the plugin_timeout - 5s

### expect_exit_codes (optional)

`default: 0`

The exit codes DOPi should expect if the program terminates. It the program
exits with an exit code not listed here, DOPi will mark the run as failed.
The values can be a number, an array of numbers or :all for all possible exit
codes. Will replace the current default.

### parse_output (optional)

`default: {}`

Here you can define patterns that match against the output of the command plugin
and flag certain lines as errors or warnings. The parse_output key should contain
a hash with two keys, 'error' and 'warning' which each can contain an array of
patterns.

## Example:

    credentials:
      'windows_kerberos':
        type: 'kerberos'
        realm: 'EXAMPLE.COM'
      'windows_login':
        type: 'username_password'
        username: 'Administrator'
        password: 'vagrant'

    steps:
      - name: 'execute a simple cmd command'
        nodes: 'all'
        command:
          plugin: 'winrm/cmd'
          credentials:
            - 'windows_kerberos'
            - 'windows_login'
          exec: 'ipconfig'
          arguments: '/all'
