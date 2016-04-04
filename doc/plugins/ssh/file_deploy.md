# DOPi Command Plugin: File Deploy SSH Command

This DOPi Plugin will deploy a file to a remote node which can be specified
inline in the plan or via file or output of an executable.

## Plugin Settings:

The ssh/file_deploy command plugin is based on the
[ssh custom command plugin](doc/plugins/ssh/custom.md) and the
[custom command plugin](doc/plugins/custom.md) and inherits all their
parameters.

It will however overwrite the **exec** parameter, so it is not possible to
set a custom command in this plugin.

### file (required)

The target file to be deployed

### content (required)

The content of the file. This can be specified directly as a string in the
yaml file or from a file if a hash is specified with a file source.

## Example:

    - name "Deploy file with inline content"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'ssh/file_deploy'
        file: '/tmp/resolv.conf'
        content: |
          domain example.com
          nameserver 1.2.3.4
          nameserver 4.3.2.1

    - name "Deploy file with content from a local file"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'ssh/file_deploy'
        file: '/tmp/resolv.conf'
        content: { file: './some/local/resolv.conf' }

    - name "Deploy file with content from a program output"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'ssh/file_deploy'
        file: '/tmp/resolv.conf'
        content: { exec: ['/bin/exec', 'hello world'] }