# DOPi Command Plugin: Reboot

This plugin will send the reboot command to a node. Then it will check if the
node actually rebooted by checking until it is unavailable and then available
again. The command will finish if DOPi is again able to login after the reboot.

## Plugin Settings:

There are currently no settings for this plugin

## Example

    - name "Wait until we can successfully login to the node"
      nodes:
        - 'web01.example.com'
      command: 'winrm/reboot'

