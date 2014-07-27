#
# Puppet Manifests
#
# Jenkner, Stefan <stefan@jenkner.org>
#

node default {
  fail "No matching for host ${hostname}!"
}

node base {
  include etckeeper

  package { [
    'atop',
    'byobu',
    'htop',
    'sudo',
    ] :
    ensure => present
  }
}

node 'kaspar.djingo.org' inherits base {

}

node 'nautilus.djingo.org' inherits base {

}

node 'nepomuk.djingo.org' inherits base {

}

