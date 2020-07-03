node 'ca.regnal.local' {
  class {'step::certificates':
    version => '0.10.0',
    cli_version => '0.10.1',
  }
}

node 'web.regnal.local' {
  class {'step::sds': 
    version => '76b5161',
    cli_version => '0.10.1',
  }
  class {'envoy':
    cluster => 'regnal',
    node    => 'web',
    version => 'v1.10.0',
    config  => 'envoy/regnal-web.yaml',
  }
  class {'regnal':
    version => 'v8',
    image   => 'buoyantio/regnal-web',
  }
}

node 'rex.regnal.local' {
  class {'step::sds': 
    version => '76b5161',
    cli_version => '0.10.1',
  }
  class {'envoy': 
    cluster => 'regnal',
    node    => 'rex',
    version => 'v1.10.0',
    config  => 'envoy/regnal-rex.yaml',
  }
  class {'regnal':
    version => 'v8',
    image   => 'buoyantio/regnal-rex-svc',
  }
}

node 'voting.regnal.local' {
  class {'step::sds': 
    version => '76b5161',
    cli_version => '0.10.1',
  }
  class {'envoy':
    cluster => 'regnal',
    node    => 'voting',
    version => 'v1.10.0',
    config  => 'envoy/regnal-voting.yaml',
  }
  class {'regnal':
    version => 'v8',
    image   => 'buoyantio/regnal-voting-svc',
  }
}
