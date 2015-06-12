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

  file{'/usr/libexec/mcollective/':            ensure => directory}
  file{'/usr/libexec/mcollective/mcollective': ensure => directory}
}
