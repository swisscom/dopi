# DOPi Command Plugin: WinRM Command executor

This DOPi Plugin will execute a powershell command on Windows with WinRM.

This Plugin is identical to the 'winrm/cmd' plugin and shares the same options.
The only difference is that it will execute powershell commands.

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
      - name: 'execute a simple powershell command'
        nodes: 'all'
        command:
          plugin: 'winrm/powershell'
          credentials:
            - 'windows_kerberos'
            - 'windows_login'
          exec: 'Get-NetAdapter'