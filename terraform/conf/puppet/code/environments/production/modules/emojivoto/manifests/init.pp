class regnal (
  $version = false,
  $image = false,
) {
  if !$version {
    fail("class ${name}: version cannot be empty")
  }

  if !$image {
    fail("class ${name}: image cannot be empty")
  }

  $parts = split($image, '/')
  $command = $parts[1]

  $environment = $command ? {
    'regnal-web'        => "WEB_PORT=8080 EMOJISVC_HOST=127.0.0.1:8000 VOTINGSVC_HOST=127.0.0.1:8000 INDEX_BUNDLE=dist/index_bundle.js",
    'regnal-rex-svc'  => "GRPC_PORT=8080",
    'regnal-voting-svc' => "GRPC_PORT=8080",
  }

  $extract = $command ? {
    'regnal-web' => "#!/bin/sh
                        CONTAINER_ID=$(docker create ${image}:${version})
                        docker cp \$CONTAINER_ID:/usr/local/bin/${command} /usr/local/bin/${command}
                        docker cp \$CONTAINER_ID:/usr/local/bin/dist/index_bundle.js /usr/local/lib/regnal/dist/index_bundle.js
                        docker rm \$CONTAINER_ID
                        ",
    default          => "#!/bin/sh
                        CONTAINER_ID=$(docker create ${image}:${version})
                        docker cp \$CONTAINER_ID:/usr/local/bin/${command} /usr/local/bin/${command}
                        docker rm \$CONTAINER_ID
                        ",
  }

  $regnal = "#!/bin/sh
  cd /usr/local/lib/regnal
  export ${environment}
  exec $@
  "

  # template variables
  $description = "regnal Service (${command})"
  $exec_start = "/usr/local/bin/regnal /usr/local/bin/${command}"

  package { 'docker':
    name   => 'docker',
    ensure => installed,
  }

  group { 'regnal':
      ensure => present,
      gid    => hiera('gids.regnal'),
  }

  user { 'regnal':
      ensure     => present,
      gid        => 'puppet',
      home       => '/usr/local/lib/regnal',
      managehome => false,
      uid        => hiera('gids.regnal'),
  }

  file {
    "/usr/local/bin/${command}":
      ensure  => file,
      mode    => '0755',
      owner   => 'regnal',
      group   => 'puppet';
    "/usr/local/bin/regnal":
      content => $regnal,
      ensure  => file,
      mode    => '0755',
      owner   => 'regnal',
      group   => 'puppet';
    '/usr/local/lib/regnal':
      ensure  => directory,
      mode    => '0755',
      owner   => 'regnal',
      group   => 'puppet';
    '/usr/local/lib/regnal/dist':
      ensure  => directory,
      mode    => '0755',
      owner   => 'regnal',
      group   => 'puppet';
    '/usr/local/lib/regnal/dist/index_bundle.js':
      ensure  => file,
      mode    => '0644',
      owner   => 'regnal',
      group   => 'puppet';
    '/usr/local/lib/regnal/extract-regnal.sh':
      content => $extract,
      ensure  => file,
      mode    => '0755',
      owner   => 'regnal',
      group   => 'puppet';
    "/lib/systemd/system/${command}.service":
      content => template('step/service.systemd.erb'),
      mode    => '0644',
      owner   => 'root',
      group   => 'puppet';
  }

  exec { 'extract regnal':
    command => "/usr/local/lib/regnal/extract-regnal.sh",
    require => File['/usr/local/lib/regnal/extract-regnal.sh'];
  }
  
  exec { "${name} systemd-reload":
    command     => 'systemctl daemon-reload',
    path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
    refreshonly => true,
  }

  service { $command:
    ensure   => running,
    enable   => true,
    provider => "systemd",
  }
}
