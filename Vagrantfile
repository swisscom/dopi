# -*- mode: ruby -*-
# vi: set ft=ruby :

# This will create the dop test machines with from a dop plan
# Please make sure you have installed dop_common as a Vagrant plugin
#
# $ vagrant plugin install path/to/dop_common-x.x.x.gem
#
require 'dop_common'

DOP_PLAN = 'spec/fixtures/testenv_plan.yaml'

hash = YAML.load_file(DOP_PLAN)
plan = DopCommon::Plan.new(hash)

Vagrant.configure(2) do |config|

  # Create vagrant boxes from the plan file
  plan.nodes.each do |node|

    config.vm.define node.name do |machine|
      machine.vm.box = node.image

      interface = node.interfaces.first
      machine.vm.network "private_network", ip: interface.ip

      # windows/linux specific settings
      if node.name[/^windows/, 0]
        machine.vm.guest = :windows
        machine.vm.hostname = node.name.split('.', 2)[0]
      else
        machine.vm.hostname = node.name
      end

      # disable the default folder sync on the nodes
      # and rsync all the stuff to the puppetmaster
      if node.name == 'puppetmaster.example.com'
        config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ".bundle/"
      else
        config.vm.synced_folder ".", "/vagrant", disabled: true
      end
    end

  end
end

