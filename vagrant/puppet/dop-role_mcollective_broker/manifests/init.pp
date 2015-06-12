# == Class: role_mcollective_broker
#
# Full description of class role_mcollective_broker here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'role_mcollective_broker':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class role_mcollective_broker inherits role_base {
  include 'java'
  include 'activemq'

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
