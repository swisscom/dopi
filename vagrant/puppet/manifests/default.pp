$my_role = hiera('my_role', 'base')

node default {
  include "role_${::my_role}"
}

