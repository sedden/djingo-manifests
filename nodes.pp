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
    'puppetmaster-passenger',
    ] :
    ensure => present
  }

  include apache

  apache::vhost { 'puppet.djingo.org':
    servername        => 'puppet.djingo.org',
    port              => '8140',
    docroot           => '/usr/share/puppet/rack/puppetmasterd/public/',
    options           => ['None'],
    rack_base_uris    => ['/'],
    request_headers   => [
      'set X-Client-DN %{SSL_CLIENT_S_DN}e',
      'set X-Client-Verify %{SSL_CLIENT_VERIFY}e',
      'set X-SSL-Subject %{SSL_CLIENT_S_DN}e',
      'unset X-Forwarded-For',
    ],
    ssl               => true,
    ssl_ca            => '/var/lib/puppet/ssl/certs/ca.pem',
    ssl_cert          => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
    ssl_chain         => '/var/lib/puppet/ssl/certs/ca.pem',
    ssl_cipher        => 'ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP',
    ssl_crl           => '/var/lib/puppet/ssl/ca/ca_crl.pem',
    ssl_crl_path      => undef,
    ssl_key           => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
    ssl_options       => ['+StdEnvVars', '+ExportCertData'],
    ssl_protocol      => '-ALL +SSLv3 +TLSv1',
    ssl_verify_client => 'optional',
    ssl_verify_depth  => '1',
  }

}

node 'nautilus.djingo.org' inherits base {

}

node 'nepomuk.djingo.org' inherits base {

}

