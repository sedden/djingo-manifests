Exec {
  path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

File {
  mode  => '0644',
  owner => 'root',
  group => 'root',
}

import 'nodes.pp'
