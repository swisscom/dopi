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

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  # Puppetmaster
  config.vm.define 'puppetmaster', primary: true do |puppetmaster|
    puppetmaster.vm.hostname = 'puppetmaster.example.com'

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

  # Mcollective Broker
  config.vm.define 'broker', primary: true do |puppetmaster|
    puppetmaster.vm.hostname = 'broker.example.com'

    puppetmaster.puppet_install.puppet_version  = '3.8.1'
  end

  # Other Machines
  [ 'mysql01',
    'web01',
    'web02',
    'haproxy01'
  ].each do |name|
    config.vm.define name do |server|
      server.vm.hostname = name + '.example.com'
    end
  end

end
