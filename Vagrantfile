# -*- mode: ruby -*-
# vi: set ft=ruby :

# This will create the dop test machines with from a dop plan
# Please make sure you have installed dop_common as a Vagrant plugin
#
# $ vagrant plugin install path/to/dop_common-x.x.x.gem
#
require 'dop_common'

DOP_PLAN = 'spec/integration/dopi/build_dop_test_environment.yaml'

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

#  config.vm.box = 'baremettle/centos-6.5'

#  config.ssh.username = 'root'
#  config.ssh.password = 'vagrant'
#  config.ssh.insert_key = 'true'

#  config.landrush.enabled = true
#  config.landrush.tld = 'com'

  # Puppetmaster
#  config.vm.define 'puppetmaster' do |puppetmaster|
#    puppetmaster.vm.hostname = 'puppetmaster.example.com'

#    puppetmaster.librarian_puppet.puppetfile_dir = 'vagrant/puppet'

#    puppetmaster.vm.provision 'puppet' do |puppet|
#      puppet.hiera_config_path = 'vagrant/puppet/hiera.yaml'
#      puppet.module_path       = 'vagrant/puppet/modules'
#      puppet.manifests_path    = 'vagrant/puppet/manifests'
#    end

#    puppetmaster.vm.provision 'file',
#      source: 'vagrant/puppet/environment.conf',
#      destination: '/etc/puppet/environments/production/environment.conf'
#  end

  # Mcollective Broker
#  config.vm.define 'broker' do |broker|
#    broker.vm.hostname = 'broker.example.com'
#  end

  # Linux test machines
#  config.vm.define 'linux01.example.com' do |node|
#    node.landrush.enabled = true
#    node.vm.hostname = 'linux01.example.com'
#  end
#  config.vm.define 'linux02' do |node|
#    node.vm.hostname = 'linux02.example.com'
#  end
#  config.vm.define 'linux03' do |node|
#    node.vm.hostname = 'linux03.example.com'
#  end

  # windows test box
#  config.vm.define 'windows01.example.com' do |node|
#    node.vm.box = 'opentable/win-2012r2-standard-amd64-nocm'
#    node.vm.guest = :windows
#    node.vm.communicator = "winrm"
#    node.vm.provider :libvirt do |domain|
#      domain.nic_model_type = 'e1000'
#    end
#  end

#end
