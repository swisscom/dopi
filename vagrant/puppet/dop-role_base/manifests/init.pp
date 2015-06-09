# == Class: role_base
#
# DOPi Base role for tests.
#
# === Authors
#
# Andreas Zuber <zuber@puzzle.ch>
#
class role_base {
  include 'puppet'
  include 'mcollective'

  # FIX: directory is missing
  file{'/usr/libexec/mcollective':
    ensure => directory
  }->
  Class['mcollective::server']

}
