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

  class { 'apache':
    default_vhost => false,
  }

  class { 'apache::mod::passenger':
    rails_autodetect             => 'Off',
    rack_autodetect              => 'Off',
    passenger_high_performance   => 'on',
    passenger_max_pool_size      => '12',
    passenger_pool_idle_time     => '1500',
    passenger_stat_throttle_rate => '120',
  }

  apache::vhost { 'puppet.djingo.org_8140':
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
    require           => Package['puppetmaster-passenger'],
  }

  postgresql::server::db { 'puppet_dashboard':
    user     => 'puppet_dashboard',
    password => postgresql_password('puppet_dashboard', 'puppet_dashboard'),
  }

  package {
    [
    'libpq-dev',
    'libsqlite3-dev',
    'libxml2-dev',
    'libxslt1-dev',
    'ruby-dev',
    ]:
    ensure => present,
  }

  bundler::install { '/var/www/puppet.djingo.org':
    deployment => true,
    require    => [
      Package['libpq-dev'],
      Package['libsqlite3-dev'],
      Package['libxml2-dev'],
      Package['libxslt1-dev'],
      Package['ruby-dev'],
      Vcsrepo['/var/www/puppet.djingo.org'],
    ],
  }

  vcsrepo { '/var/www/puppet.djingo.org':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/sodabrew/puppet-dashboard',
  }
  ~>
  file { '/var/www/puppet.djingo.org/config.ru':
    ensure => present,
    owner  => 'puppet',
    group  => 'puppet',
  }

  apache::vhost { 'puppet.djingo.org_80':
    servername     => 'puppet.djingo.org',
    port           => '80',
    docroot        => '/var/www/puppet.djingo.org/public/',
    options        => ['None'],
    rack_base_uris => ['/'],
    require        => File['/var/www/puppet.djingo.org/config.ru'],
  }

  package { [ 'nodejs' ]:
    ensure => present,
  }

  # TODO: complete installation
  # $ cd /var/www/puppet.djingo.org
  # $ sudo -s
  # $ echo "secret_token: '$(bundle exec rake secret)'" >> config/settings.yml
  # $ RAILS_ENV=production bundle exec rake db:setup
  # $ RAILS_ENV=production bundle exec rake db:migrate
  # $ RAILS_ENV=production bundle exec rake assets:precompile

}

node 'nautilus.djingo.org' inherits base {

}

node 'nepomuk.djingo.org' inherits base {

}

