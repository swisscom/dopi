# This site.pp is the entry point for puppet in the testenv
# It contains some workarounds to help with problems in the
# used modules

$role = hiera('role')

class base {
  hiera_include('classes')

  file{'/usr/libexec/mcollective/':            ensure => directory}
  file{'/usr/libexec/mcollective/mcollective': ensure => directory}
}

node default {
  include base
}

node 'puppetmaster.example.com' {
  include base

   file{'/etc/puppet/autosign.conf':
    content => "*.example.com\n",
    mode    => '0664',
  }

  #file{'/etc/puppet/environments/production/manifests/': ensure => directory }
  file{'/etc/puppet/environments/production/manifests/site.pp':
    ensure => symlink,
    target => '/etc/puppet/manifests/site.pp',
  }

}

# This are some fixes because there is not realy a working
# mcollective module for centos at the moment
node 'broker.example.com' {
  include base

  # FIX for activemq module
  file{'/etc/activemq/':                    ensure => directory }
  file{'/etc/activemq/instances-available': ensure => directory }
  file{'/etc/activemq/instances-enabled':   ensure => directory }

  # This is probably needed because we use an debian module or something
  file{'/etc/activemq/activemq.xml':
    source  => 'file:///etc/activemq/instances-available/mcollective/activemq.xml',
    require => File['/etc/activemq/instances-available/mcollective/activemq.xml'],
    notify  => Service['activemq'],
  }

  Class['java'] -> Class['activemq']
}
