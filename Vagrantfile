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

  config.puppet_install.puppet_version  = '3.8.1'

  # Puppetmaster
  config.vm.define 'puppetmaster' do |puppetmaster|
    puppetmaster.vm.hostname = 'puppetmaster.example.com'

    puppetmaster.librarian_puppet.puppetfile_dir = 'vagrant/puppet'

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
  config.vm.define 'broker' do |broker|
    broker.vm.hostname = 'broker.example.com'
  end

  # Linux test machines
  config.vm.define 'linux01' do |node|
    node.vm.hostname = 'linux01.example.com'
  end
  config.vm.define 'linux02' do |node|
    node.vm.hostname = 'linux02.example.com'
  end
  config.vm.define 'linux03' do |node|
    node.vm.hostname = 'linux03.example.com'
  end
  config.vm.define 'linux04' do |node|
    node.vm.hostname = 'linux04.example.com'
  end
  config.vm.define 'linux05' do |node|
    node.vm.hostname = 'linux05.example.com'
  end


  # windows test box
  config.vm.define 'windows01' do |server|
    server.vm.hostname = 'windows01.example.com'
    server.vm.box = 'opentable/win-2012r2-standard-amd64-nocm'
    server.vm.communicator = "winrm"
    server.hostmanager.manage_host = true
  end

end
