# == Class: role_puppetmaster
#
# Deploys a Puppetmaster and a MCO Broker.
#
# Andreas Zuber <zuber@puzzle.ch>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class role_puppetmaster inherits role_base {
  include 'foreman'
}

