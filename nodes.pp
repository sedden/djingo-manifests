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

  include postgresql::server

  postgresql::server::db { 'puppet':
    user     => 'puppet',
    password => postgresql_password('puppet', 'puppet'),
  }

  package { [
    'ruby-pg',
    'ruby-activerecord',
    ] :
    ensure => present
  }

}

node 'nautilus.djingo.org' inherits base {

}

node 'nepomuk.djingo.org' inherits base {

}

