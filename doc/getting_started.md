# Getting started with DOPi

This guide is a good starting point if you are new to DOPi and want to
learn how to use it to automate your node provisioning.

To start make sure you installed DOPi according to the instructions in
the [README](README.md).

You will find all the examples written in this tutorial in the example
directory next to this file.

## Hello World

Let's start with a typical hello world plan file and analyze what
parts are required to actually use DOPi. Use your favored editor to
create a file called 'hello_world.yaml' with the following content:

    name: 'hello_world'

    infrastructures:
      'test':
        type: 'baremetal'

    nodes:
      'testlinux.example.com':
        infrastructure: 'test'

    steps:
      - name: 'write hello world'
        nodes: 'all'
        command:
          plugin: 'custom'
          exec: 'echo'
          arguments: '"hello world"'

Now let's try to use DOPi to run that plan. There are usually a
few steps required to run a plan. Here is what you have to do:

    $ dopi add hello_world.yaml
    New plan hello_world was added
    hello_world

We just added the 'hello_world' plan to our plan cache. DOPi tells
us that this was successful and returns the handle 'hello_world'.
We will require this handle to do other stuff with the plan we
just added. The handle is in fact the same as the 'name' attribute
at the very top of the plan file. It is always good to chose a name
which describes best what the content is. You can use letters,
numbers, '-' and '_' but no spaces or any other kind of character in
the name.

The plan cache is just a directory which holds all your added plans
and some files for the state of the plans. This cache will also be
used by the dop-hiera plugin if you have any configuration data in
your plans (more on this later).

The standard directory for the plan cache is ~/.dop/cache if you run
DOPi as user or /var/lib/dop/plans if you run it as root. You can also
overwrite this with the global '--plan_cache_dir' option.

To list what plans are already added in your plan cache you can simply
list them with DOPi:

    $ dopi list
    hello_world

We can see that it contains our 'hello_world' plan file. To see what
the state of the plan is and what steps are defined we can show
the content of the plan with DOPi:

    $ dopi show hello_world
    [ready] hello_world
      [ready] default
        [ready] write hello world
          [ready] testlinux.example.com

Now we see a whole hierarchy with every part in the state 'ready'.
The first line represents the state of the whole plan. You can only
run a plan which is in the state ready. If part of the plan is in
the state 'failed' it will reflect that in the plan state.

The second line represents the step set. You can separate your steps
in your plan into different sets, so they can be executed independendly
of eachother (more on that later). We did not specify a step set in our
hello_world.yaml, so DOPi will create a default step set for us.

The third line represents the step and it is named after the name
attribute we specified in the first step in the hello_world.yaml file.
A step is executed on a number of nodes and they are listed under each
step with their state, which represents the last line in the output.

So now that we know that our plan is ready we can execute it for the
first time. But maybe we want to check first what it actually does.
To accomplish this we run the plan in 'noop' mode first to see
exactly what commands get executed:

    $ dopi run --noop hello_world
    Starting signal handling
    Starting to run step 'write hello world'
      [Command] testlinux.example.com : Running command custom
      [Command] testlinux.example.com : (NOOP) Executing 'echo "hello world"' for command custom
      [Command] testlinux.example.com : (NOOP) Environment: {"DOP_NODE_FQDN"=>"testlinux.example.com"}
    [ready] hello_world
      [ready] default
        [ready] write hello world
          [ready] testlinux.example.com

Now you can see that DOPi will run the command 'echo "hello world"' as
we have specified in the plan file. Now let's remove the 'noop' option
and actually run it:

    $ dopi run hello_world
    Starting signal handling
    Starting to run step 'write hello world'
      [Command] testlinux.example.com : Running command custom
      [Command] testlinux.example.com : custom [OK]
    Step 'write hello world' successfully finished.
    [done] hello_world
      [done] default
        [done] write hello world
          [done] testlinux.example.com

DOPi successfully executed the plan and the state changed from 'ready'
to 'done'.

## Connecting over SSH

Until now we only executed commands on the local machine. But the main
purpose of DOPi is to connect to a machine and execute some commands
to make it ready or execute a configuration management tool like Puppet.

To make it easy to demonstrate this we will use the ssh plugin like you
normaly would to connect to a remote machine, but we will configure DOPi
so it actually connect to localhost.

First we add a network to the infrastructures hash:

    infrastructures:
      'test':
        type: 'baremetal'
        networks:
          'localhost':
            ip_pool:
              from: '127.0.0.2'
              to:   '127.0.0.250'
            ip_netmask: '255.255.255.0'
            ip_defgw: '127.0.0.1'

We defined the network 'localhost' and a range of IPs. Now we have to
add our existing machine into this network by adding a network interface:

    nodes:
      'testlinux.example.com':
        infrastructure: 'test'
        interfaces:
          'eth0':
            network: 'localhost'
            ip: '127.0.0.2'

Then we need to make sure we can access the local machine with SSH. We
have to provide some credentials to login to the machine. This is done
in the credentials hash:

    credentials:
      'test-credentials':
        type: 'ssh_key'
        username: 'myuser'
        private_key: '/home/myuser/.ssh/id_rsa'

In this case we will use an SSH private key to connect to local host.
Make sure your public key is in your '~/.ssh/authorized_keys' file.
You can also define a username/password pair if you don't want to use
a private key, make sure you check the syntax in the documentation.

Now we change the plugin in the step and use the 'ssh/custom' plugin
instead of 'custom'. DOPi will now connect to the node and execute
the command via SSH. We also need to tell the plugin what credentials
it should use. Make sure the step looks like this now:

    steps:
      - name: 'write hello world'
        nodes: 'all'
        command:
          plugin: 'ssh/custom'
          credentials: 'test-credentials'
          exec: 'echo'
          arguments: '"hello world"'

This tells DOPi to use the previously defined credentials to login to
the machine. Let's update the plan:

    $ bundle exec dopi update --plan hello_world.yaml hello_world
    Updating plan hello_world
    Plan hello_world was removed
    New plan hello_world was added
    hello_world

Updating the plan will always reset the state of the the steps since
we may completely change them and there is no way for DOPi to know
what states should be preserves (This may change in the future).

Let's run in noop mode:

    $ bundle exec dopi run --noop hello_world
    Starting signal handling
    Starting to run step 'write hello world'
      [Command] testlinux.example.com : Running command ssh/custom
      [Command] testlinux.example.com : (NOOP) Executing 'ssh  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  -q  -o ChallengeResponseAuthentication=no  -o PasswordAuthentication=no  -i /home/myuser/.ssh/id_rsa myuser@127.0.0.2 "DOP_NODE_FQDN=testlinux.example.com echo \"hello world\""' for command ssh/custom
      [Command] testlinux.example.com : (NOOP) Environment: {"DOP_NODE_FQDN"=>"testlinux.example.com"}
    [ready] hello_world
      [ready] default
        [ready] write hello world
          [ready] testlinux.example.com

We see that DOPi will actually use ssh to connect to the node and
execute the step.

    $ bundle exec dopi run hello_world 
    Starting signal handling
    Starting to run step 'write hello world'
      [Command] testlinux.example.com : Running command ssh/custom
      [Command] testlinux.example.com : ssh/custom [OK]
    Step 'write hello world' successfully finished.
    [done] hello_world
      [done] default
        [done] write hello world
          [done] testlinux.example.com

We can successfully run the step.

## Idempotency

As we have seen before if we update a plan we lose the state and
have to rerun all the steps. Sometimes this may not be what we want.
In any case, it is always good practice to write your steps in a way
so you can rerun them as many times as you want.

In DOPi this is made easy with verification commands which run prior
to the actual command and check if we can skip the step or not.



DOPi oneshot adds the plan to the plan cache, runs it and at the
end removes it from the cache again. We will learn more about the
different methods to run a plan later, for now we will use the
oneshot command because it is useful to test or if you don't care
about the state of a plan.
