# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = 'baremettle/centos-6.5'

  config.ssh.username = 'root'
  config.ssh.password = 'vagrant'
  config.ssh.insert_key = 'true'


  # Puppetmaster and MCollective broker
  config.vm.define 'puppetmaster', primary: true do |puppetmaster|
    puppetmaster.vm.hostname = 'puppetmaster.example.com'

    puppetmaster.vm.network :private_network,
      :ip => '192.168.122.101',
      :libvirt__network_name => 'default'

    puppetmaster.librarian_puppet.puppetfile_dir = 'vagrant/puppet'
    puppetmaster.puppet_install.puppet_version  = '3.8.1'

    puppetmaster.vm.provision 'puppet' do |puppet|
      puppet.hiera_config_path = 'vagrant/puppet/hiera.yaml'
      puppet.module_path       = 'vagrant/puppet/modules'
      puppet.manifests_path    = 'vagrant/puppet/manifests'
    end

    puppetmaster.vm.provision 'file',
      source: 'vagrant/puppet/environment.conf',
      destination: '/etc/puppet/environments/production/environment.conf'
  end

  # SSH Test Machines
  ssh_test_machines = {
    'mysql01' => {
      :ip => '192.168.122.103'
    },
    'web01' => {
      :ip => '192.168.122.104'
    },
    'web02' => {
      :ip => '192.168.122.105'
    },
    'haproxy01' => {
      :ip => '192.168.122.106'
    },
  }

  ssh_test_machines.keys.each do |name|
    config.vm.define name do |server|
      server.vm.hostname = name + '.example.com'

      server.vm.network :private_network,
        :ip => ssh_test_machines[name][:ip],
        :libvirt__network_name => 'default'
    end
  end

end
