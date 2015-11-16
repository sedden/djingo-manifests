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
    'mr',
    'sudo',
    'vcsh',
    ] :
    ensure => present
  }

  # puppet.conf [agent] section
  ini_setting { 'puppet pluginsync':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'agent',
    setting => 'pluginsync',
    value   => 'true',
  }
  ini_setting { 'puppet server':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'agent',
    setting => 'server',
    value   => 'puppet.djingo.org',
  }
  ini_setting { 'puppet report':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'agent',
    setting => 'report',
    value   => 'true',
  }

}

node 'kaspar.djingo.org' inherits base {

  host { 'puppet.djingo.org':
    ip           => '127.0.0.1',
    host_aliases => 'puppet',
    before       => Package['puppetmaster-common'],
  }

  include postgresql::server

  postgresql::server::db { 'puppet_master':
    user     => 'puppet',
    password => postgresql_password('puppet', 'puppet'),
  }

  package { [
    'ruby-pg',
    'ruby-activerecord',
    'puppetmaster-common',
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

  # puppet.conf [master] section
  ini_setting { 'puppet master storeconfigs':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'master',
    setting => 'storeconfigs',
    value   => 'true',
    require => Package['puppetmaster-common'],
  }
  ini_setting { 'puppet master dbadapter':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'master',
    setting => 'dbadapter',
    value   => 'postgresql',
    require => Package['puppetmaster-common'],
  }
  ini_setting { 'puppet master dbserver':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'master',
    setting => 'dbserver',
    value   => '/var/run/postgresql',
    require => Package['puppetmaster-common'],
  }
  ini_setting { 'puppet master dbname':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'master',
    setting => 'dbname',
    value   => 'puppet_master',
    require => Package['puppetmaster-common'],
  }
  ini_setting { 'puppet master reports':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'master',
    setting => 'reports',
    value   => 'store, http',
    require => Package['puppetmaster-common'],
  }
  ini_setting { 'puppet master reporturl':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'master',
    setting => 'reporturl',
    value   => 'http://localhost:80/reports/upload',
    require => Package['puppetmaster-common'],
  }

  postgresql::server::db { 'puppet_dashboard':
    user     => 'puppet',
    password => postgresql_password('puppet', 'puppet'),
  }

  package {
    [
    'g++',
    'libmysqlclient-dev',
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
  ~>
  apache::vhost { 'puppet.djingo.org_80':
    servername      => 'puppet.djingo.org',
    port            => '80',
    docroot         => '/var/www/puppet.djingo.org/public/',
    options         => ['None'],
    rack_base_uris  => ['/'],
    custom_fragment => '
    <Location />
      Order deny,allow
      Deny from all
      Allow from ::1
      Allow from fe00::0
      Allow from 127.0.0.0/8
    </Location>
    ',
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

  # kaspar/secure.djingo.org
  include apache::mod::suphp

  file { '/var/www/kaspar.djingo.org':
    ensure => directory,
  }
  apache::vhost { 'kaspar.djingo.org_80':
    servername       => 'kaspar.djingo.org',
    port             => '443',
    ssl              => true,
    docroot          => '/var/www/kaspar.djingo.org',
    suphp_addhandler => 'x-httpd-php',
    suphp_engine     => 'on',
    suphp_configpath => '/etc/php5/apache2',
    directories      => [
      {
        path           => '/var/www/kaspar.djingo.org/cloud',
        options        => ['Indexes','FollowSymLinks','MultiViews'],
        allow_override => ['All'],
        #require        => 'all granted',
      },
    ],
    require          => File['/var/www/kaspar.djingo.org'],
  }

  # ownCloud
  package { [
    'php5-gd',
    'php5-json',
    'php5-pgsql',
    'php5-curl',
    'php5-intl',
    'php5-mcrypt',
    'php5-imagick',
    ] : ensure => present,
  }
  postgresql::server::db { 'owncloud':
    user     => 'owncloud',
    password => postgresql_password('owncloud', 'owncloud'),
  }
  file { '/var/www/kaspar.djingo.org/cloud':
    ensure => directory,
    owner  => 'owncloud',
    group  => 'owncloud',
  }

}

node 'nautilus.djingo.org' inherits base {

}

node 'nepomuk.djingo.org' inherits base {

}
